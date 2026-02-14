# frozen_string_literal: true

class KanbanContactSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :phone_number,
             :email,
             :kanban_stage_id,
             :created_at,
             :last_activity_at

  attribute :thumbnail do
    object.avatar_url
  end

  attribute :labels do
    object.labels.map do |label|
      {
        id: label.id,
        title: label.title,
        color: label.color
      }
    end
  end

  attribute :value do
    object.custom_attributes&.dig('valor_negocio').to_f || 0
  rescue StandardError
    0
  end

  attribute :conversations_count do
    object.conversations.count
  end

  attribute :last_conversation do
    last_conv = object.conversations.order(last_activity_at: :desc).first
    return nil unless last_conv

    {
      id: last_conv.id,
      display_id: last_conv.display_id,
      status: last_conv.status,
      last_activity_at: last_conv.last_activity_at
    }
  end
end