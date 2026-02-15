# frozen_string_literal: true

class Api::V1::Accounts::Kanban::CustomFieldValuesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_conversation

  def index
    @values = @conversation.kanban_custom_field_values.includes(:kanban_custom_field)
    render json: values_json
  end

  def update
    results = []
    params[:fields]&.each do |field_data|
      field = KanbanCustomField.find_by(id: field_data[:field_id])
      next unless field

      value_record = @conversation.kanban_custom_field_values
                                  .find_or_initialize_by(kanban_custom_field_id: field.id)
      value_record.value = field_data[:value]
      value_record.save
      results << value_record
    end

    render json: values_json
  end

  def bulk_update
    params[:values]&.each do |field_key, value|
      field = find_field_by_key(field_key)
      next unless field

      value_record = @conversation.kanban_custom_field_values
                                  .find_or_initialize_by(kanban_custom_field_id: field.id)
      value_record.value = value.to_s
      value_record.save
    end

    render json: values_json
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def find_field_by_key(key)
    return nil unless @conversation.kanban_stage&.kanban_pipeline

    @conversation.kanban_stage.kanban_pipeline.kanban_custom_fields.find_by(field_key: key)
  end

  def values_json
    stage = @conversation.kanban_stage
    pipeline = stage&.kanban_pipeline

    # Sempre retorna has_pipeline para o frontend saber se está no CRM
    unless pipeline
      return {
        has_pipeline: false,
        stage: nil,
        pipeline: nil,
        fields: [],
        values: {}
      }
    end

    fields = pipeline.kanban_custom_fields.ordered
    values = @conversation.kanban_custom_field_values.includes(:kanban_custom_field)

    values_hash = values.each_with_object({}) do |v, hash|
      hash[v.field_key] = {
        field_id: v.kanban_custom_field_id,
        value: v.value,
        typed_value: v.typed_value
      }
    end

    {
      has_pipeline: true,
      stage: {
        id: stage.id,
        name: stage.name,
        color: stage.color
      },
      pipeline: {
        id: pipeline.id,
        name: pipeline.name
      },
      fields: fields.map { |f| field_json(f) },
      values: values_hash
    }
  end

  def field_json(field)
    {
      id: field.id,
      name: field.name,
      field_key: field.field_key,
      field_type: field.field_type,
      description: field.description,
      select_options: field.select_options,
      required: field.required,
      show_on_card: field.show_on_card
    }
  end
end
