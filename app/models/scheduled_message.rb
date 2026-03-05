# == Schema Information
#
# Table name: scheduled_messages
#
#  id              :bigint           not null, primary key
#  content         :text             not null
#  scheduled_at    :datetime         not null
#  status          :integer          default("pending"), null: false
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint           not null
#  conversation_id :bigint
#  user_id         :bigint           not null
#
# Indexes
#
#  index_scheduled_messages_on_account_id_and_status  (account_id,status)
#  index_scheduled_messages_on_contact_id             (contact_id)
#  index_scheduled_messages_on_conversation_id        (conversation_id)
#  index_scheduled_messages_on_scheduled_at_and_status  (scheduled_at,status)
#  index_scheduled_messages_on_user_id                (user_id)
#
class ScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :user
  belongs_to :conversation, optional: true

  enum status: { pending: 0, sent: 1, failed: 2 }

  validates :content, presence: true
  validates :scheduled_at, presence: true

  scope :pending, -> { where(status: :pending) }
end
