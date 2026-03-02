# frozen_string_literal: true

require 'csv'

class Api::V1::Accounts::Kanban::BoardController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline

  def show
    stages = @pipeline.kanban_stages.ordered

    # Pré-carregar configuração dos campos personalizados
    @custom_fields_config = @pipeline.kanban_custom_fields.ordered

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
      sort_by: params[:sort_by] || 'last_activity',
      available_filters: available_filters,
      custom_fields_config: @custom_fields_config.map { |cf| custom_field_config_json(cf) }
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

  def export
    stages = @pipeline.kanban_stages.ordered
    
    csv_data = CSV.generate(headers: true, col_sep: ';') do |csv|
      # Header
      headers = [
        'ID', 'Contato', 'Email', 'Telefone', 'Estágio', 'Valor',
        'Status', 'Motivo Perda', 'Vendedor', 'Criado em', 'Última Atividade'
      ]
      
      # Adicionar campos personalizados ao header
      custom_fields = @pipeline.kanban_custom_fields.ordered
      custom_fields.each { |cf| headers << cf.name }
      
      csv << headers
      
      # Dados
      stages.each do |stage|
        conversations = stage.conversations.includes(:contact, :assignee, :kanban_custom_field_values)
        
        conversations.each do |conv|
          row = [
            conv.display_id,
            conv.contact&.name,
            conv.contact&.email,
            conv.contact&.phone_number,
            stage.name,
            conv.deal_value,
            conv.closed_won.nil? ? 'Aberto' : (conv.closed_won ? 'Ganho' : 'Perdido'),
            conv.closed_reason,
            conv.assignee&.name,
            conv.created_at&.strftime('%d/%m/%Y %H:%M'),
            conv.last_activity_at&.strftime('%d/%m/%Y %H:%M')
          ]
          
          # Adicionar valores dos campos personalizados
          custom_fields.each do |cf|
            value = conv.kanban_custom_field_values.find { |v| v.kanban_custom_field_id == cf.id }&.value
            row << value
          end
          
          csv << row
        end
      end
    end
    
    send_data csv_data,
              filename: "kanban_#{@pipeline.name.parameterize}_#{Date.current}.csv",
              type: 'text/csv; charset=utf-8'
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def conversations_for_stage(stage)
    conversations = stage.conversations.includes(:contact, :assignee, :kanban_custom_field_values, :kanban_tasks)

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

# Filtro por data de entrada
if params[:date_field].present? && params[:date_value].present?
  date_field = params[:date_field] # 'created_at' ou 'updated_at'
  date_value = params[:date_value]
  
  # Formato: ano (2024)
  if date_value.match?(/^\d{4}$/)
    conversations = conversations.where("YEAR(conversations.#{date_field}) = ?", date_value.to_i)
  
  # Formato: mês/ano (2024-02)
  elsif date_value.match?(/^\d{4}-\d{2}$/)
    conversations = conversations.where("DATE_FORMAT(conversations.#{date_field}, '%Y-%m') = ?", date_value)
  
  # Formato: data completa (2024-02-27)
  elsif date_value.match?(/^\d{4}-\d{2}-\d{2}$/)
    conversations = conversations.where("DATE(conversations.#{date_field}) = ?", date_value)
  end
end
    
# Filtro por campo personalizado
if params[:custom_field].present? && params[:custom_value].present?
  field = @pipeline.kanban_custom_fields.find_by(field_key: params[:custom_field])
  if field
    # ✅ NOVO: Tratamento especial para campo created_at (data de entrada)
    if params[:custom_field] == 'created_at'
      date_value = params[:custom_value]
      
      # Formato: ano (2024)
      if date_value.match?(/^\d{4}$/)
        conversations = conversations.where("YEAR(conversations.created_at) = ?", date_value.to_i)
      
      # Formato: mês/ano (2024-02)
      elsif date_value.match?(/^\d{4}-\d{2}$/)
        conversations = conversations.where("DATE_FORMAT(conversations.created_at, '%Y-%m') = ?", date_value)
      
      # Formato: data completa (2024-02-27)
      elsif date_value.match?(/^\d{4}-\d{2}-\d{2}$/)
        conversations = conversations.where("DATE(conversations.created_at) = ?", date_value)
      end
    else
      # Filtro normal para outros campos personalizados
      conversation_ids = KanbanCustomFieldValue
        .where(kanban_custom_field_id: field.id)
        .where('value LIKE ?', "%#{params[:custom_value]}%")
        .pluck(:conversation_id)
      conversations = conversations.where(id: conversation_ids)
    end
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

    # Filtro por tarefas
    if params[:tasks_filter].present?
      case params[:tasks_filter]
      when 'with_tasks'
        conversation_ids = KanbanTask.where(status: ['pending', 'in_progress']).pluck(:conversation_id).uniq
        conversations = conversations.where(id: conversation_ids)
      when 'overdue'
        conversation_ids = KanbanTask.where(status: ['pending', 'in_progress']).where('due_at < ?', Time.current).pluck(:conversation_id).uniq
        conversations = conversations.where(id: conversation_ids)
      when 'due_today'
        today = Time.current.beginning_of_day..Time.current.end_of_day
        conversation_ids = KanbanTask.where(status: ['pending', 'in_progress']).where(due_at: today).pluck(:conversation_id).uniq
        conversations = conversations.where(id: conversation_ids)
      when 'no_tasks'
        conversation_ids = KanbanTask.where(status: ['pending', 'in_progress']).pluck(:conversation_id).uniq
        conversations = conversations.where.not(id: conversation_ids)
      end
    end

    # Aplicar ordenação
    conversations = apply_sorting(conversations)

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

  def apply_sorting(conversations)
    case params[:sort_by]
    when 'value_desc'
      conversations.order('deal_value DESC NULLS LAST')
    when 'value_asc'
      conversations.order('deal_value ASC NULLS LAST')
    when 'newest'
      conversations.order(created_at: :desc)
    when 'oldest'
      conversations.order(created_at: :asc)
    when 'last_activity'
      conversations.order(last_activity_at: :desc)
    else
      conversations.order(last_activity_at: :desc)
    end
  end

  def filters_applied?
    params[:assignee_id].present? ||
      params[:deal_status].present? ||
      params[:min_value].present? ||
      params[:max_value].present? ||
      params[:search].present? ||
      params[:custom_field].present? ||
      params[:custom_fields].present? ||
      params[:tasks_filter].present?
  end

  def available_filters
    {
      assignees: Current.account.users.map { |u| { id: u.id, name: u.name } },
      custom_fields: @custom_fields_config.map do |cf|
        {
          field_key: cf.field_key,
          name: cf.name,
          field_type: cf.field_type,
          select_options: cf.select_options,
          show_on_card: cf.show_on_card
        }
      end
    }
  end

  def conversation_json(conv)
    # Montar valores dos campos personalizados com informações completas
    custom_field_values = conv.kanban_custom_field_values.map do |cfv|
      field_config = @custom_fields_config.find { |cf| cf.id == cfv.kanban_custom_field_id }
      next unless field_config

      {
        field_key: cfv.kanban_custom_field.field_key,
        field_type: field_config.field_type,
        name: field_config.name,
        value: cfv.value,
        show_on_card: field_config.show_on_card
      }
    end.compact

    # Também manter o formato antigo para compatibilidade
    custom_fields_hash = conv.kanban_custom_field_values.each_with_object({}) do |cfv, hash|
      hash[cfv.kanban_custom_field.field_key] = cfv.value
    end

    pending_tasks_count = conv.kanban_tasks.where(status: ['pending', 'in_progress']).count
    overdue_tasks_count = conv.kanban_tasks.where(status: ['pending', 'in_progress']).where('due_at < ?', Time.current).count

    {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      kanban_stage_id: conv.kanban_stage_id,
      deal_value: conv.deal_value,
      closed_won: conv.closed_won,
      closed_reason: conv.closed_reason,
      closed_at: conv.closed_at,
      custom_fields: custom_fields_hash,
      custom_field_values: custom_field_values,
      tasks: {
        pending: pending_tasks_count,
        overdue: overdue_tasks_count
      },
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

  def custom_field_config_json(field)
    {
      id: field.id,
      field_key: field.field_key,
      name: field.name,
      field_type: field.field_type,
      show_on_card: field.show_on_card,
      select_options: field.select_options
    }
  end
end


