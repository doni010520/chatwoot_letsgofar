class ScheduledMessages::SendJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Rails.logger.info "[ScheduledMessages] Starting job at #{Time.current}"
    
    # Busca apenas mensagens pending prontas para envio
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
    
    Messages::MessageBuilder.new(
      user: message.user,
      conversation: conversation,
      params: {
        content: message.content,
        message_type: :outgoing,
        private: false
      }
    ).perform
  end
  
  def find_or_create_conversation(message)
    # Busca conversa aberta do contato
    conversation = message.contact.conversations
      .where(account_id: message.account_id)
      .where.not(status: :resolved)
      .last
    
    # Se não existir, cria nova
    unless conversation
      inbox = message.account.inboxes.find_by(id: message.inbox_id)
      
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
