# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline

  def show
    board_data = build_board_data

    render json: {
      pipeline: KanbanPipelineSerializer.new(@pipeline).as_json,
      board: board_data,
      totals: calculate_board_totals(board_data)
    }
  end

  def move
    item = find_item
    new_stage = find_new_stage

    ActiveRecord::Base.transaction do
      item.update!(kanban_stage: new_stage)
    end

    broadcast_move(item)

    render json: {
      success: true,
      item: serialize_item(item)
    }
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def build_board_data
    stages_data = @pipeline.kanban_stages.ordered.map do |stage|
      {
        stage: KanbanStageSerializer.new(stage).as_json,
        items: fetch_items_for_stage(stage),
        totals: calculate_stage_totals(stage)
      }
    end

    stages_data << build_unassigned_column
    stages_data
  end

  def build_unassigned_column
    {
      stage: {
        id: nil,
        name: 'Não atribuído',
        color: '#9CA3AF',
        position: -1
      },
      items: fetch_unassigned_items,
      totals: calculate_unassigned_totals
    }
  end

  def fetch_items_for_stage(stage)
    case @pipeline.pipeline_type
    when 'conversations'
      serialize_conversations(stage.conversations)
    when 'contacts'
      serialize_contacts(stage.contacts)
    when 'both'
      {
        conversations: serialize_conversations(stage.conversations),
        contacts: serialize_contacts(stage.contacts)
      }
    end
  end

  def fetch_unassigned_items
    case @pipeline.pipeline_type
    when 'conversations'
      serialize_conversations(unassigned_conversations.limit(100))
    when 'contacts'
      serialize_contacts(unassigned_contacts.limit(100))
    when 'both'
      {
        conversations: serialize_conversations(unassigned_conversations.limit(50)),
        contacts: serialize_contacts(unassigned_contacts.limit(50))
      }
    end
  end

  def unassigned_conversations
    Current.account.conversations
           .not_in_kanban
           .includes(:contact, :assignee, :labels, :inbox)
           .order(last_activity_at: :desc)
  end

  def unassigned_contacts
    Current.account.contacts
           .not_in_kanban
           .includes(:labels)
           .order(last_activity_at: :desc)
  end

  def serialize_conversations(conversations)
    conversations.includes(:contact, :assignee, :labels, :inbox).map do |conv|
      KanbanConversationSerializer.new(conv).as_json
    end
  end

  def serialize_contacts(contacts)
    contacts.includes(:labels).map do |contact|
      KanbanContactSerializer.new(contact).as_json
    end
  end

  def calculate_stage_totals(stage)
    case @pipeline.pipeline_type
    when 'conversations'
      stage.totals_for_conversations
    when 'contacts'
      stage.totals_for_contacts
    when 'both'
      {
        conversations: stage.totals_for_conversations,
        contacts: stage.totals_for_contacts
      }
    end
  end

  def calculate_unassigned_totals
    { count: 0, value: 0 }
  end

  def calculate_board_totals(board_data)
    totals = { count: 0, value: 0.0 }

    board_data.each do |column|
      stage_totals = column[:totals]

      if stage_totals.is_a?(Hash) && stage_totals[:conversations]
        totals[:count] += stage_totals.dig(:conversations, :count).to_i
        totals[:count] += stage_totals.dig(:contacts, :count).to_i
        totals[:value] += stage_totals.dig(:conversations, :value).to_f
        totals[:value] += stage_totals.dig(:contacts, :value).to_f
      else
        totals[:count] += stage_totals[:count].to_i
        totals[:value] += stage_totals[:value].to_f
      end
    end

    totals
  end

  def find_item
    case params[:item_type]
    when 'conversation'
      Current.account.conversations.find(params[:item_id])
    when 'contact'
      Current.account.contacts.find(params[:item_id])
    else
      raise ActiveRecord::RecordNotFound, 'Item type inválido'
    end
  end

  def find_new_stage
    return nil if params[:to_stage_id].blank?

    @pipeline.kanban_stages.find(params[:to_stage_id])
  end

  def serialize_item(item)
    case params[:item_type]
    when 'conversation'
      KanbanConversationSerializer.new(item).as_json
    when 'contact'
      KanbanContactSerializer.new(item).as_json
    end
  end

  def broadcast_move(item)
    ActionCable.server.broadcast(
      "kanban:#{Current.account.id}",
      {
        event: 'item_moved',
        item_type: params[:item_type],
        item_id: item.id,
        from_stage_id: params[:from_stage_id],
        to_stage_id: params[:to_stage_id],
        pipeline_id: @pipeline.id,
        item: serialize_item(item)
      }
    )
  rescue StandardError => e
    Rails.logger.error "Erro ao broadcast kanban move: #{e.message}"
  end
end