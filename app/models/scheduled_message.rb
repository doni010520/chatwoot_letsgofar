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

  # Anexos
  has_many_attached :files

  # Tipos de arquivo permitidos
  ALLOWED_FILE_CONTENT_TYPES = %w[
    image/png image/jpeg image/gif image/bmp image/webp image/svg+xml
    video/mp4 video/quicktime video/webm video/x-msvideo
    audio/mpeg audio/ogg audio/wav audio/webm
    application/pdf
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/zip application/x-rar-compressed application/gzip
    text/plain text/csv
  ].freeze

  MAX_FILE_SIZE = 300.megabytes

  enum status: { pending: 0, sent: 1, failed: 2 }

  validates :content, presence: true
  validates :scheduled_at, presence: true
  validate :validate_attached_files

  scope :pending, -> { where(status: :pending) }

  private

  def validate_attached_files
    files.each do |file|
      if file.byte_size > MAX_FILE_SIZE
        errors.add(:files, "#{file.filename} excede o tamanho maximo de 300MB")
      end
      unless ALLOWED_FILE_CONTENT_TYPES.include?(file.content_type)
        errors.add(:files, "#{file.filename} possui um tipo de arquivo nao permitido (#{file.content_type})")
      end
    end
  end
end
