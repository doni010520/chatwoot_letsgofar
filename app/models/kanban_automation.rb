# app/models/kanban_automation.rb
class KanbanAutomation < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :kanban_pipeline
  has_many :conditions, class_name: 'KanbanAutomationCondition', dependent: :destroy
  has_many :actions, class_name: 'KanbanAutomationAction', dependent: :destroy
  has_many :logs, class_name: 'KanbanAutomationLog', dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :actions, allow_destroy: true

  # Validations
  validates :name, presence: true
  validates :trigger_type, presence: true, inclusion: { in: %w[
    stage_changed
    deal_won
    deal_lost
    deal_value_changed
    conversation_added
    task_overdue
    task_completed
    lead_stale
  ] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_trigger, ->(trigger) { where(trigger_type: trigger) }
  scope :ordered, -> { order(execution_order: :asc, created_at: :asc) }

  # Trigger types with descriptions
  TRIGGER_TYPES = {
    'stage_changed' => {
      name: 'Mudança de Estágio',
      description: 'Dispara quando uma conversa muda de estágio',
      config_fields: %w[from_stage_id to_stage_id]
    },
    'deal_won' => {
      name: 'Negócio Ganho',
      description: 'Dispara quando um negócio é marcado como ganho',
      config_fields: []
    },
    'deal_lost' => {
      name: 'Negócio Perdido',
      description: 'Dispara quando um negócio é marcado como perdido',
      config_fields: %w[loss_reason]
    },
    'deal_value_changed' => {
      name: 'Valor Alterado',
      description: 'Dispara quando o valor do negócio é alterado',
      config_fields: %w[min_value max_value]
    },
    'conversation_added' => {
      name: 'Lead Adicionado',
      description: 'Dispara quando uma conversa é adicionada ao CRM',
      config_fields: %w[stage_id]
    },
    'task_overdue' => {
      name: 'Tarefa Vencida',
      description: 'Dispara quando uma tarefa fica vencida',
      config_fields: []
    },
    'task_completed' => {
      name: 'Tarefa Concluída',
      description: 'Dispara quando uma tarefa é concluída',
      config_fields: []
    },
    'lead_stale' => {
      name: 'Lead Parado',
      description: 'Dispara quando um lead fica parado por X dias',
      config_fields: %w[days stage_id]
    }
  }.freeze

  def self.trigger_types_for_select
    TRIGGER_TYPES.map { |key, value| { value: key, label: value[:name], description: value[:description] } }
  end

  def trigger_info
    TRIGGER_TYPES[trigger_type] || {}
  end

  # Check if automation matches the trigger event
  def matches_trigger?(event_data)
    case trigger_type
    when 'stage_changed'
      matches_stage_changed?(event_data)
    when 'deal_won', 'deal_lost', 'task_overdue', 'task_completed', 'conversation_added'
      true # Always matches for these simple triggers
    when 'deal_value_changed'
      matches_value_changed?(event_data)
    when 'lead_stale'
      matches_lead_stale?(event_data)
    else
      false
    end
  end

  # Check if conversation passes all conditions
  def conditions_met?(conversation, event_data = {})
    return true if conditions.empty?

    conditions.all? do |condition|
      condition.evaluate(conversation, event_data)
    end
  end

  # Record execution
  def record_execution!
    update(
      executions_count: executions_count + 1,
      last_executed_at: Time.current
    )
  end

  private

  def matches_stage_changed?(event_data)
    from_stage = trigger_config['from_stage_id']
    to_stage = trigger_config['to_stage_id']

    # If no specific stages configured, match any change
    return true if from_stage.blank? && to_stage.blank?

    # Check from_stage if configured
    if from_stage.present? && event_data[:from_stage_id].to_s != from_stage.to_s
      return false
    end

    # Check to_stage if configured
    if to_stage.present? && event_data[:to_stage_id].to_s != to_stage.to_s
      return false
    end

    true
  end

  def matches_value_changed?(event_data)
    min_value = trigger_config['min_value'].to_f
    max_value = trigger_config['max_value'].to_f
    new_value = event_data[:new_value].to_f

    return false if min_value.positive? && new_value < min_value
    return false if max_value.positive? && new_value > max_value

    true
  end

  def matches_lead_stale?(event_data)
    configured_days = trigger_config['days'].to_i
    configured_stage = trigger_config['stage_id']

    return false if configured_days.positive? && event_data[:days_stale].to_i < configured_days
    return false if configured_stage.present? && event_data[:stage_id].to_s != configured_stage.to_s

    true
  end
end
