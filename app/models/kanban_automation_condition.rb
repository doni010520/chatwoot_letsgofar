# app/models/kanban_automation_condition.rb
class KanbanAutomationCondition < ApplicationRecord
  # Associations
  belongs_to :kanban_automation

  # Validations
  validates :field, presence: true
  validates :operator, presence: true, inclusion: { in: %w[
    equals
    not_equals
    greater_than
    less_than
    greater_or_equal
    less_or_equal
    contains
    not_contains
    starts_with
    ends_with
    is_empty
    is_not_empty
    is_true
    is_false
  ] }

  # Scopes
  scope :ordered, -> { order(position: :asc) }

  # Available fields for conditions
  CONDITION_FIELDS = {
    'stage_id' => { name: 'Estágio', type: 'select', source: 'stages' },
    'deal_value' => { name: 'Valor do Negócio', type: 'number' },
    'assignee_id' => { name: 'Responsável', type: 'select', source: 'users' },
    'contact_name' => { name: 'Nome do Contato', type: 'text' },
    'contact_email' => { name: 'Email do Contato', type: 'text' },
    'contact_phone' => { name: 'Telefone do Contato', type: 'text' },
    'inbox_id' => { name: 'Inbox', type: 'select', source: 'inboxes' },
    'labels' => { name: 'Labels', type: 'multiselect', source: 'labels' },
    'days_in_stage' => { name: 'Dias no Estágio', type: 'number' },
    'days_since_last_activity' => { name: 'Dias sem Atividade', type: 'number' },
    'custom_field' => { name: 'Campo Personalizado', type: 'custom' }
  }.freeze

  # Operators by type
  OPERATORS_BY_TYPE = {
    'text' => %w[equals not_equals contains not_contains starts_with ends_with is_empty is_not_empty],
    'number' => %w[equals not_equals greater_than less_than greater_or_equal less_or_equal],
    'select' => %w[equals not_equals is_empty is_not_empty],
    'multiselect' => %w[contains not_contains is_empty is_not_empty],
    'boolean' => %w[is_true is_false],
    'custom' => %w[equals not_equals contains not_contains is_empty is_not_empty greater_than less_than]
  }.freeze

  def self.fields_for_select
    CONDITION_FIELDS.map { |key, config| { value: key, label: config[:name], type: config[:type] } }
  end

  def self.operators_for_type(type)
    OPERATORS_BY_TYPE[type] || OPERATORS_BY_TYPE['text']
  end

  # Evaluate the condition against a conversation
  def evaluate(conversation, event_data = {})
    field_value = get_field_value(conversation, event_data)
    compare(field_value, operator, value)
  end

  private

  def get_field_value(conversation, event_data)
    case field
    when 'stage_id'
      conversation.kanban_stage_id
    when 'deal_value'
      conversation.deal_value.to_f
    when 'assignee_id'
      conversation.assignee_id
    when 'contact_name'
      conversation.contact&.name
    when 'contact_email'
      conversation.contact&.email
    when 'contact_phone'
      conversation.contact&.phone_number
    when 'inbox_id'
      conversation.inbox_id
    when 'labels'
      conversation.labels.pluck(:id)
    when 'days_in_stage'
      calculate_days_in_stage(conversation)
    when 'days_since_last_activity'
      calculate_days_since_activity(conversation)
    when /^custom_field:(.+)$/
      get_custom_field_value(conversation, ::Regexp.last_match(1))
    else
      event_data[field.to_sym]
    end
  end

  def calculate_days_in_stage(conversation)
    last_stage_change = conversation.kanban_activities
                                    .where(activity_type: 'stage_changed')
                                    .order(created_at: :desc)
                                    .first

    return 0 unless last_stage_change

    ((Time.current - last_stage_change.created_at) / 1.day).to_i
  end

  def calculate_days_since_activity(conversation)
    return 0 unless conversation.last_activity_at

    ((Time.current - conversation.last_activity_at) / 1.day).to_i
  end

  def get_custom_field_value(conversation, field_key)
    custom_value = conversation.kanban_custom_field_values
                               .joins(:kanban_custom_field)
                               .find_by(kanban_custom_fields: { field_key: field_key })
    custom_value&.value
  end

  def compare(field_value, operator, condition_value)
    case operator
    when 'equals'
      field_value.to_s == condition_value.to_s
    when 'not_equals'
      field_value.to_s != condition_value.to_s
    when 'greater_than'
      field_value.to_f > condition_value.to_f
    when 'less_than'
      field_value.to_f < condition_value.to_f
    when 'greater_or_equal'
      field_value.to_f >= condition_value.to_f
    when 'less_or_equal'
      field_value.to_f <= condition_value.to_f
    when 'contains'
      return field_value.include?(condition_value.to_i) if field_value.is_a?(Array)

      field_value.to_s.downcase.include?(condition_value.to_s.downcase)
    when 'not_contains'
      return !field_value.include?(condition_value.to_i) if field_value.is_a?(Array)

      !field_value.to_s.downcase.include?(condition_value.to_s.downcase)
    when 'starts_with'
      field_value.to_s.downcase.start_with?(condition_value.to_s.downcase)
    when 'ends_with'
      field_value.to_s.downcase.end_with?(condition_value.to_s.downcase)
    when 'is_empty'
      field_value.blank?
    when 'is_not_empty'
      field_value.present?
    when 'is_true'
      field_value == true || field_value == 'true' || field_value == '1'
    when 'is_false'
      field_value == false || field_value == 'false' || field_value == '0' || field_value.nil?
    else
      false
    end
  end
end
