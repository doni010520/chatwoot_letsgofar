# frozen_string_literal: true

class KanbanConversationSerializer < ActiveModel::Serializer
  attributes :id,
             :display_id,
             :status,
             :last_activity_at,
             :kanban_stage_id,
             :created_at

  attribute :contact do
    return nil unless object.contact

    {
      id: object.contact.id,
      name: object.contact.name,
      phone_number: object.contact.phone_number,
      email: object.contact.email,
      thumbnail: object.contact.avatar_url
    }
  end

  attribute :assignee do
    return nil unless object.assignee

    {
      id: object.assignee.id,
      name: object.assignee.name,
      thumbnail: object.assignee.avatar_url
    }
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

  attribute :inbox do
    return nil unless object.inbox

    {
      id: object.inbox.id,
      name: object.inbox.name,
      channel_type: object.inbox.channel_type
    }
  end

  attribute :unread_count do
    object.unread_incoming_messages.count
  end

  attribute :last_message_at do
    object.last_activity_at
  end
end