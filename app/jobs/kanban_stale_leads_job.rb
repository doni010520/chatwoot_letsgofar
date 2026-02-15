# app/jobs/kanban_stale_leads_job.rb
class KanbanStaleLeadsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Run daily to check for stale leads
  def perform
    Rails.logger.info '[KanbanStaleLeadsJob] Starting stale leads check...'

    # Find all active automations with lead_stale trigger
    automations = KanbanAutomation
                  .active
                  .by_trigger('lead_stale')
                  .includes(:kanban_pipeline)

    automations.each do |automation|
      process_automation(automation)
    end

    Rails.logger.info '[KanbanStaleLeadsJob] Completed'
  end

  private

  def process_automation(automation)
    days_threshold = automation.trigger_config['days'].to_i
    return if days_threshold.zero?

    stage_filter = automation.trigger_config['stage_id']
    pipeline = automation.kanban_pipeline

    # Find conversations in this pipeline that are stale
    conversations = Conversation
                    .joins(:kanban_stage)
                    .where(kanban_stages: { kanban_pipeline_id: pipeline.id })
                    .where(closed_won: nil) # Only open deals
                    .where('conversations.last_activity_at < ?', days_threshold.days.ago)

    # Filter by stage if configured
    conversations = conversations.where(kanban_stage_id: stage_filter) if stage_filter.present?

    Rails.logger.info "[KanbanStaleLeadsJob] Found #{conversations.count} stale leads for automation ##{automation.id}"

    conversations.find_each do |conversation|
      days_stale = ((Time.current - conversation.last_activity_at) / 1.day).to_i

      KanbanAutomationService.on_lead_stale(conversation, days_stale)
    end
  end
end
