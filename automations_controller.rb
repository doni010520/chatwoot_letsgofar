# app/controllers/api/v1/accounts/kanban/automations_controller.rb
class Api::V1::Accounts::Kanban::AutomationsController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline
  before_action :set_automation, only: %i[show update destroy toggle logs test]

  def index
    @automations = @pipeline.kanban_automations
                            .includes(:conditions, :actions)
                            .ordered

    render json: {
      automations: @automations.map { |a| automation_json(a) },
      meta: {
        trigger_types: KanbanAutomation.trigger_types_for_select,
        action_types: KanbanAutomationAction.action_types_for_select,
        condition_fields: KanbanAutomationCondition.fields_for_select
      }
    }
  end

  def show
    render json: automation_json(@automation, include_logs: true)
  end

  def create
    @automation = @pipeline.kanban_automations.new(automation_params)
    @automation.account = Current.account

    if @automation.save
      render json: automation_json(@automation), status: :created
    else
      render json: { errors: @automation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @automation.update(automation_params)
      render json: automation_json(@automation)
    else
      render json: { errors: @automation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @automation.destroy
    head :no_content
  end

  def toggle
    @automation.update(is_active: !@automation.is_active)
    render json: automation_json(@automation)
  end

  def logs
    logs = @automation.logs
                      .includes(:conversation)
                      .recent
                      .limit(params[:limit] || 50)

    render json: {
      logs: logs.map { |log| log_json(log) },
      stats: {
        total: @automation.logs.count,
        successful: @automation.logs.successful.count,
        failed: @automation.logs.failed.count,
        last_executed: @automation.last_executed_at
      }
    }
  end

  def test
    # Find a sample conversation to test
    conversation = @pipeline.kanban_stages
                            .joins(:conversations)
                            .first&.conversations
                            &.first

    unless conversation
      return render json: { error: 'Nenhuma conversa encontrada para testar' }, status: :unprocessable_entity
    end

    # Simulate trigger
    event_data = build_test_event_data

    log = @automation.logs.create!(
      conversation_id: conversation.id,
      trigger_data: event_data.merge(test: true),
      status: 'pending'
    )

    # Check conditions
    unless @automation.conditions_met?(conversation, event_data)
      log.mark_failed!('Condições não atendidas')
      return render json: {
        success: false,
        message: 'Condições não atendidas para esta conversa de teste',
        log: log_json(log)
      }
    end

    # Execute actions (dry run)
    results = []
    @automation.actions.ordered.each do |action|
      result = { action_type: action.action_type, simulated: true }
      results << result
    end

    log.mark_success!(results)

    render json: {
      success: true,
      message: 'Teste executado com sucesso (simulação)',
      conversation_id: conversation.id,
      results: results,
      log: log_json(log)
    }
  end

  # Metadata endpoints
  def trigger_types
    render json: KanbanAutomation.trigger_types_for_select
  end

  def action_types
    render json: KanbanAutomationAction.action_types_for_select
  end

  def condition_fields
    render json: KanbanAutomationCondition.fields_for_select
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def set_automation
    @automation = @pipeline.kanban_automations.find(params[:id])
  end

  def automation_params
    params.require(:automation).permit(
      :name,
      :description,
      :trigger_type,
      :is_active,
      :execution_order,
      trigger_config: {},
      conditions_attributes: %i[id field operator value position _destroy],
      actions_attributes: [:id, :action_type, :position, :_destroy, { action_config: {} }]
    )
  end

  def automation_json(automation, include_logs: false)
    json = {
      id: automation.id,
      name: automation.name,
      description: automation.description,
      trigger_type: automation.trigger_type,
      trigger_info: automation.trigger_info,
      trigger_config: automation.trigger_config,
      is_active: automation.is_active,
      execution_order: automation.execution_order,
      executions_count: automation.executions_count,
      last_executed_at: automation.last_executed_at,
      conditions: automation.conditions.ordered.map { |c| condition_json(c) },
      actions: automation.actions.ordered.map { |a| action_json(a) },
      created_at: automation.created_at,
      updated_at: automation.updated_at
    }

    if include_logs
      json[:recent_logs] = automation.logs.recent.limit(10).map { |l| log_json(l) }
    end

    json
  end

  def condition_json(condition)
    {
      id: condition.id,
      field: condition.field,
      operator: condition.operator,
      value: condition.value,
      position: condition.position
    }
  end

  def action_json(action)
    {
      id: action.id,
      action_type: action.action_type,
      action_info: action.action_info,
      action_config: action.action_config,
      config_fields: action.config_fields,
      position: action.position
    }
  end

  def log_json(log)
    {
      id: log.id,
      conversation_id: log.conversation_id,
      conversation_display_id: log.conversation&.display_id,
      contact_name: log.conversation&.contact&.name,
      trigger_data: log.trigger_data,
      actions_executed: log.actions_executed,
      status: log.status,
      status_label: log.status_label,
      error_message: log.error_message,
      executed_at: log.executed_at,
      created_at: log.created_at
    }
  end

  def build_test_event_data
    case @automation.trigger_type
    when 'stage_changed'
      stages = @pipeline.kanban_stages.ordered.limit(2)
      {
        from_stage_id: stages.first&.id,
        to_stage_id: stages.second&.id || stages.first&.id,
        from_stage_name: stages.first&.name,
        to_stage_name: stages.second&.name || stages.first&.name
      }
    when 'deal_value_changed'
      { old_value: 1000, new_value: 2000 }
    when 'lead_stale'
      { days_stale: @automation.trigger_config['days'].to_i || 7 }
    else
      {}
    end
  end
end
