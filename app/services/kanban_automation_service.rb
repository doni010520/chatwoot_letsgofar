# app/services/kanban_automation_service.rb
class KanbanAutomationService
  attr_reader :account, :conversation, :trigger_type, :event_data, :current_user

  def initialize(conversation:, trigger_type:, event_data: {}, current_user: nil)
    @conversation = conversation
    @account = conversation.account
    @trigger_type = trigger_type
    @event_data = event_data
    @current_user = current_user
  end

  # Main entry point - find and execute matching automations
  def execute
    return unless conversation.kanban_stage_id.present?

    pipeline = conversation.kanban_stage.kanban_pipeline

    automations = KanbanAutomation
                  .where(kanban_pipeline_id: pipeline.id)
                  .active
                  .by_trigger(trigger_type)
                  .ordered

    Rails.logger.info "[KanbanAutomation] Found #{automations.count} automations for trigger '#{trigger_type}'"

    automations.each do |automation|
      process_automation(automation)
    end
  end

  # Class method for easy triggering
  def self.trigger(conversation:, trigger_type:, event_data: {}, current_user: nil)
    new(
      conversation: conversation,
      trigger_type: trigger_type,
      event_data: event_data,
      current_user: current_user
    ).execute
  end

  # Trigger helpers for specific events
  def self.on_stage_changed(conversation, from_stage, to_stage, current_user = nil)
    event_data = {
      from_stage_id: from_stage&.id,
      to_stage_id: to_stage&.id,
      from_stage_name: from_stage&.name,
      to_stage_name: to_stage&.name
    }

    trigger(
      conversation: conversation,
      trigger_type: 'stage_changed',
      event_data: event_data,
      current_user: current_user
    )
  end

  def self.on_deal_won(conversation, current_user = nil)
    trigger(
      conversation: conversation,
      trigger_type: 'deal_won',
      event_data: { deal_value: conversation.deal_value },
      current_user: current_user
    )
  end

  def self.on_deal_lost(conversation, reason, current_user = nil)
    trigger(
      conversation: conversation,
      trigger_type: 'deal_lost',
      event_data: { deal_value: conversation.deal_value, reason: reason },
      current_user: current_user
    )
  end

  def self.on_value_changed(conversation, old_value, new_value, current_user = nil)
    trigger(
      conversation: conversation,
      trigger_type: 'deal_value_changed',
      event_data: { old_value: old_value, new_value: new_value },
      current_user: current_user
    )
  end

  def self.on_conversation_added(conversation, stage, current_user = nil)
    trigger(
      conversation: conversation,
      trigger_type: 'conversation_added',
      event_data: { stage_id: stage.id, stage_name: stage.name },
      current_user: current_user
    )
  end

  def self.on_task_overdue(conversation, task)
    trigger(
      conversation: conversation,
      trigger_type: 'task_overdue',
      event_data: { task_id: task.id, task_title: task.title, due_at: task.due_at }
    )
  end

  def self.on_task_completed(conversation, task, current_user = nil)
    trigger(
      conversation: conversation,
      trigger_type: 'task_completed',
      event_data: { task_id: task.id, task_title: task.title },
      current_user: current_user
    )
  end

  def self.on_lead_stale(conversation, days_stale)
    trigger(
      conversation: conversation,
      trigger_type: 'lead_stale',
      event_data: {
        days_stale: days_stale,
        stage_id: conversation.kanban_stage_id,
        stage_name: conversation.kanban_stage&.name
      }
    )
  end

  private

  def process_automation(automation)
    # Check if trigger matches
    unless automation.matches_trigger?(event_data)
      Rails.logger.debug "[KanbanAutomation] Automation ##{automation.id} trigger not matched"
      return
    end

    # Check if conditions are met
    unless automation.conditions_met?(conversation, event_data)
      Rails.logger.debug "[KanbanAutomation] Automation ##{automation.id} conditions not met"
      return
    end

    # Create log entry
    log = automation.logs.create!(
      conversation_id: conversation.id,
      trigger_data: event_data,
      status: 'pending'
    )

    # Execute actions
    execute_actions(automation, log)
  end

  def execute_actions(automation, log)
    log.mark_running!
    results = []

    begin
      automation.actions.ordered.each do |action|
        Rails.logger.info "[KanbanAutomation] Executing action '#{action.action_type}' for conversation ##{conversation.id}"

        result = action.execute(conversation, event_data, current_user)
        results << result.merge(action_type: action.action_type, action_id: action.id)

        # Stop on failure if critical
        if result[:success] == false && result[:critical]
          raise "Critical action failed: #{result[:error]}"
        end
      end

      log.mark_success!(results)
      automation.record_execution!

      Rails.logger.info "[KanbanAutomation] Automation ##{automation.id} completed successfully"
    rescue StandardError => e
      Rails.logger.error "[KanbanAutomation] Automation ##{automation.id} failed: #{e.message}"
      log.mark_failed!(e.message)
    end
  end
end
