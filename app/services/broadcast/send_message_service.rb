# frozen_string_literal: true

# Envia UMA mensagem de um disparo para um destinatário, via a inbox de API
# (Channel::Api). Criar a mensagem de saída dispara o webhook da inbox -> n8n
# -> uazapi -> WhatsApp (mesmo caminho das mensagens dos agentes).
module Broadcast
  class SendMessageService
    def initialize(campaign:, recipient:)
      @campaign = campaign
      @recipient = recipient
    end

    def call
      Current.account = account
      Current.user = @campaign.user

      content = Broadcast::MessagePersonalizer.new(@campaign.message_template, @recipient).call
      conversation = ensure_conversation

      Messages::MessageBuilder.new(
        @campaign.user,
        conversation,
        ActionController::Parameters.new(content: content, message_type: 'outgoing')
      ).perform

      @recipient.mark_sent!(conversation_id: conversation.display_id, message: content)
    ensure
      Current.reset
    end

    private

    def account
      @campaign.account
    end

    def inbox
      @campaign.inbox
    end

    # E.164 com '+', mesmo formato do source_id que já existe na instância.
    def e164
      "+#{@recipient.phone}"
    end

    def contact
      @contact ||= account.contacts.find_by(phone_number: e164) ||
                   account.contacts.create!(name: @recipient.name.presence || e164, phone_number: e164)
    end

    def contact_inbox
      contact.contact_inboxes.find_by(inbox_id: inbox.id) ||
        ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: e164).perform
    end

    def ensure_conversation
      contact_inbox.conversations.order(:id).last ||
        ConversationBuilder.new(params: ActionController::Parameters.new({}), contact_inbox: contact_inbox).perform
    end
  end
end
