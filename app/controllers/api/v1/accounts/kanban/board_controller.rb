# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline

  def show
    stages = @pipeline.kanban_stages.ordered

    board_data = stages.map do |stage|
      items = if @pipeline.pipeline_type == 'contacts'
                contacts_for_stage(stage)
              else
                conversations_for_stage(stage)
              end

      stage_value = items.sum { |item| item[:deal_value].to_f }

      {
        stage: stage_json(stage),
        items: items,
        totals: { count: items.size, value: stage_value }
      }
    end

    render json: {
      pipeline: pipeline_json(@pipeline),
      board: board_data,
      totals: {
        count: board_data.sum { |col| col[:totals][:count] },
        value: board_data.sum { |col| col[:totals][:value] }
      },
      filters_applied: filters_applied?,
      available_filters: available_filters
    }
  end

  def move
    item_type = params[:item_type]
    item_id = params[:item_id]
    to_stage_id = params[:to_stage_id]

    item = if item_type == 'contact'
             Current.account.contacts.find(item_id)
           else
             Current.account.conversations.find(item_id)
           end

    item.update!(kanban_stage_id: to_stage_id.presence)
    head :ok
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def conversations_for_stage(stage)
    conversations = stage.conversations.includes(:contact, :assignee, :kanban_custom_field_values)

    # Filtro por vendedor
    if params[:assignee_id].present?
      conversations = conversations.where(assignee_id: params[:assignee_id])
    end

    # Filtro por status (aberto/ganho/perdido)
    case params[:deal_status]
    when 'open'
      conversations = conversations.where(closed_won: nil)
    when 'won'
      conversations = conversations.where(closed_won: true)
    when 'lost'
      conversations = conversations.where(closed_won: false)
    end

    # Filtro por valor mínimo
    if params[:min_value].present?
      conversations = conversations.where('deal_value >= ?', params[:min_value].to_f)
    end

    # Filtro por valor máximo
    if params[:max_value].present?
      conversations = conversations.where('deal_value <= ?', params[:max_value].to_f)
    end

    # Filtro por busca (nome do contato)
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      conversations = conversations.joins(:contact).where(
        'LOWER(contacts.name) LIKE ? OR LOWER(contacts.email) LIKE ? OR contacts.phone_number LIKE ?',
        search_term, search_term, search_term
      )
    end

    # Filtro por campo personalizado
    if params[:custom_field].present? && params[:custom_value].present?
      field = @pipeline.kanban_custom_fields.find_by(field_key: params[:custom_field])
      if field
        conversation_ids = KanbanCustomFieldValue
          .where(kanban_custom_field_id: field.id)
          .where('value LIKE ?', "%#{params[:custom_value]}%")
          .pluck(:conversation_id)
        conversations = conversations.where(id: conversation_ids)
      end
    end

    # Filtros múltiplos de campos personalizados (formato: custom_fields[field_key]=value)
    if params[:custom_fields].present? && params[:custom_fields].is_a?(ActionController::Parameters)
      params[:custom_fields].each do |field_key, value|
        next if value.blank?

        field = @pipeline.kanban_custom_fields.find_by(field_key: field_key)
        next unless field

        conversation_ids = KanbanCustomFieldValue
          .where(kanban_custom_field_id: field.id)
          .where('value LIKE ?', "%#{value}%")
          .pluck(:conversation_id)
        conversations = conversations.where(id: conversation_ids)
      end
    end

    conversations.limit(100).map do |conv|
      conversation_json(conv)
    end
  end

  def contacts_for_stage(stage)
    contacts = stage.contacts

    # Filtro por busca
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      contacts = contacts.where(
        'LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR phone_number LIKE ?',
        search_term, search_term, search_term
      )
    end

    contacts.limit(100).map do |contact|
      contact_json(contact)
    end
  end

  def filters_applied?
    params[:assignee_id].present? ||
      params[:deal_status].present? ||
      params[:min_value].present? ||
      params[:max_value].present? ||
      params[:search].present? ||
      params[:custom_field].present? ||
      params[:custom_fields].present?
  end

  def available_filters
    {
      assignees: Current.account.users.map { |u| { id: u.id, name: u.name } },
      custom_fields: @pipeline.kanban_custom_fields.ordered.map do |cf|
        {
          field_key: cf.field_key,
          name: cf.name,
          field_type: cf.field_type,
          select_options: cf.select_options
        }
      end
    }
  end

  def conversation_json(conv)
    custom_field_values = conv.kanban_custom_field_values.each_with_object({}) do |cfv, hash|
      hash[cfv.kanban_custom_field.field_key] = cfv.value
    end

    {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      kanban_stage_id: conv.kanban_stage_id,
      deal_value: conv.deal_value,
      closed_won: conv.closed_won,
      closed_reason: conv.closed_reason,
      closed_at: conv.closed_at,
      custom_fields: custom_field_values,
      contact: conv.contact ? {
        id: conv.contact.id,
        name: conv.contact.name,
        email: conv.contact.email,
        phone_number: conv.contact.phone_number,
        thumbnail: conv.contact.avatar_url
      } : nil,
      assignee: conv.assignee ? {
        id: conv.assignee.id,
        name: conv.assignee.name
      } : nil,
      last_activity_at: conv.last_activity_at
    }
  end

  def contact_json(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      thumbnail: contact.avatar_url,
      kanban_stage_id: contact.kanban_stage_id
    }
  end

  def pipeline_json(pipeline)
    {
      id: pipeline.id,
      name: pipeline.name,
      description: pipeline.description,
      pipeline_type: pipeline.pipeline_type,
      is_default: pipeline.is_default,
      kanban_stages: pipeline.kanban_stages.order(:position).map { |s| stage_json(s) }
    }
  end

  def stage_json(stage)
    {
      id: stage.id,
      name: stage.name,
      color: stage.color,
      position: stage.position
    }
  end
end
