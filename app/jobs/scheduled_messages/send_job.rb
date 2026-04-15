class ScheduledMessages::SendJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Rails.logger.info "[ScheduledMessages] Starting job at #{Time.current}"

    ScheduledMessage
      .where(status: :pending)
      .where('scheduled_at <= ?', Time.current)
      .find_each do |message|

        Rails.logger.info "[ScheduledMessages] Processing message ##{message.id}"

        begin
          send_message(message)
          message.update!(status: :sent)
          Rails.logger.info "[ScheduledMessages] Message ##{message.id} sent successfully"
        rescue => e
          message.update!(status: :failed)
          Rails.logger.error "[ScheduledMessages] Failed to send message ##{message.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
  end

  private

  def send_message(message)
    conversation = message.conversation || find_or_create_conversation(message)

    # Coletar signed_ids dos arquivos anexados para enviar como attachments
    attachment_signed_ids = message.files.map { |file| file.blob.signed_id }

    builder_params = {
      content: message.content,
      message_type: :outgoing,
      private: false
    }

    # Adicionar attachments se houver arquivos
    builder_params[:attachments] = attachment_signed_ids if attachment_signed_ids.present?

    Messages::MessageBuilder.new(
      message.user,
      conversation,
      builder_params
    ).perform
  end

  def find_or_create_conversation(message)
    conversation = message.contact.conversations
      .where(account_id: message.account_id)
      .where.not(status: :resolved)
      .last

    unless conversation
      inbox = message.account.inboxes.first

      conversation = Conversation.create!(
        account: message.account,
        inbox: inbox,
        contact: message.contact,
        status: :open
      )
    end

    conversation
  end
end
