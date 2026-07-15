# frozen_string_literal: true

class BroadcastRecipient < ApplicationRecord
  belongs_to :broadcast_campaign
  belongs_to :account

  STATUSES = %w[pending sent failed skipped].freeze

  validates :phone, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :ordered, -> { order(:position, :id) }

  def mark_sent!(conversation_id:, message:)
    update!(
      status: 'sent',
      conversation_id: conversation_id,
      personalized_message: message,
      sent_at: Time.current,
      error: nil
    )
  end

  def mark_failed!(reason)
    update!(status: 'failed', error: reason.to_s[0, 500])
  end
end
