class ScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :user

  validates :content, presence: true
  validates :scheduled_at, presence: true

  enum status: { pending: 0, sent: 1, failed: 2, cancelled: 3 }

  scope :pending, -> { where(status: :pending) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
end
