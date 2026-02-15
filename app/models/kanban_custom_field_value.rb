# frozen_string_literal: true

class KanbanCustomFieldValue < ApplicationRecord
  belongs_to :kanban_custom_field
  belongs_to :conversation

  validates :kanban_custom_field_id, uniqueness: { scope: :conversation_id }

  delegate :field_type, :field_key, :name, to: :kanban_custom_field

  def typed_value
    return nil if value.blank?

    case field_type
    when 'number'
      value.to_f
    when 'currency'
      value.to_f
    when 'checkbox'
      ActiveModel::Type::Boolean.new.cast(value)
    when 'date'
      Date.parse(value) rescue value
    when 'multiselect'
      JSON.parse(value) rescue [value]
    else
      value
    end
  end

  def typed_value=(new_value)
    self.value = case field_type
                 when 'multiselect'
                   new_value.is_a?(Array) ? new_value.to_json : new_value
                 when 'checkbox'
                   new_value.to_s
                 else
                   new_value.to_s
                 end
  end
end
