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
      assign_conversation(conversation)

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
      @contact ||= existing_contact || account.contacts.create!(name: @recipient.name.presence || e164, phone_number: e164)
    end

    # Reusa o contato certo p/ não duplicar (o que quebra o relay uazapi):
    # 1) se veio de "Contatos salvos", usa o contact_id direto;
    # 2) senão, casa o telefone considerando as variantes do 9º dígito (BR).
    def existing_contact
      if @recipient.contact_id.present?
        found = account.contacts.find_by(id: @recipient.contact_id)
        return found if found
      end
      phone_variants.each do |phone|
        found = account.contacts.find_by(phone_number: phone)
        return found if found
      end
      nil
    end

    # Ex.: +5571993061031 (com 9) <-> +557193061031 (sem 9)
    def phone_variants
      digits = @recipient.phone.to_s.gsub(/\D/, '')
      variants = ["+#{digits}"]
      if digits.start_with?('55')
        rest = digits[2..].to_s # depois do DDI
        if rest.length == 11 && rest[2] == '9'
          variants << "+55#{rest[0, 2]}#{rest[3..]}" # remove o 9
        elsif rest.length == 10
          variants << "+55#{rest[0, 2]}9#{rest[2..]}" # adiciona o 9
        end
      end
      variants.uniq
    end

    def contact_inbox
      contact.contact_inboxes.find_by(inbox_id: inbox.id) ||
        ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: contact.phone_number).perform
    end

    def ensure_conversation
      contact_inbox.conversations.order(:id).last ||
        ConversationBuilder.new(params: ActionController::Parameters.new({}), contact_inbox: contact_inbox).perform
    end

    # Atribui a conversa ao responsável do disparo (ou a quem criou, por padrão).
    def assign_conversation(conversation)
      assignee_id = @campaign.assignee_id || @campaign.user_id
      return if assignee_id.blank?
      return if conversation.assignee_id == assignee_id

      conversation.update!(assignee_id: assignee_id)
    end
  end
end
