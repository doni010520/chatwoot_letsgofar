# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline

  def show
    stages = @pipeline.kanban_stages.ordered

    # Coluna "Não Atribuído" primeiro
    board_data = [unassigned_column]

    # Depois as colunas dos estágios
    stages.each do |stage|
      items = if @pipeline.pipeline_type == 'contacts'
                contacts_for_stage(stage)
              else
                conversations_for_stage(stage)
              end

      board_data << {
        stage: stage_json(stage),
        items: items,
        totals: { count: items.size, value: 0 }
      }
    end

    render json: {
      pipeline: pipeline_json(@pipeline),
      board: board_data,
      totals: {
        count: board_data.sum { |col| col[:totals][:count] },
        value: 0
      }
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

  def unassigned_column
    items = if @pipeline.pipeline_type == 'contacts'
              unassigned_contacts
            else
              unassigned_conversations
            end

    {
      stage: {
        id: nil,
        name: 'Não Atribuído',
        color: '#6B7280',
        position: -1
      },
      items: items,
      totals: { count: items.size, value: 0 }
    }
  end

  def unassigned_conversations
    Current.account.conversations
           .where(kanban_stage_id: nil)
           .includes(:contact, :assignee)
           .order(last_activity_at: :desc)
           .limit(100)
           .map { |conv| conversation_json(conv) }
  end

  def unassigned_contacts
    Current.account.contacts
           .where(kanban_stage_id: nil)
           .order(updated_at: :desc)
           .limit(100)
           .map { |contact| contact_json(contact) }
  end

  def conversations_for_stage(stage)
    stage.conversations.includes(:contact, :assignee).limit(50).map do |conv|
      conversation_json(conv)
    end
  end

  def contacts_for_stage(stage)
    stage.contacts.limit(50).map do |contact|
      contact_json(contact)
    end
  end

  def conversation_json(conv)
    {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      kanban_stage_id: conv.kanban_stage_id,
      contact: conv.contact ? {
        id: conv.contact.id,
        name: conv.contact.name,
        email: conv.contact.email,
        phone_number: conv.contact.phone_number
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
