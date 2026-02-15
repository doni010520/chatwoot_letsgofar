# frozen_string_literal: true

class KanbanActivity < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user, optional: true

  ACTIVITY_TYPES = %w[
    stage_changed
    deal_value_changed
    marked_won
    marked_lost
    reopened
    note_added
    call_logged
    email_sent
    meeting_scheduled
    proposal_sent
    task_created
    task_completed
    custom
  ].freeze

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }

  def self.log(conversation, activity_type, user: nil, title: nil, description: nil, metadata: {})
    create!(
      account_id: conversation.account_id,
      conversation_id: conversation.id,
      user_id: user&.id,
      activity_type: activity_type,
      title: title,
      description: description,
      metadata: metadata
    )
  end
end
