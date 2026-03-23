# frozen_string_literal: true

class ContractMailer < ApplicationMailer
  default from: ENV.fetch('CONTRACT_MAILER_FROM', 'Let\'s Go Far Contratos <contratos@letsgofar.com.br>')
  layout 'mailer/contract'

  # Configurar SMTP separado para contratos (Resend)
  def self.delivery_method
    if ENV['RESEND_API_KEY'].present?
      :smtp
    else
      ActionMailer::Base.delivery_method
    end
  end

  def self.smtp_settings
    if ENV['RESEND_API_KEY'].present?
      {
        address: 'smtp.resend.com',
        port: 587,
        user_name: 'resend',
        password: ENV['RESEND_API_KEY'],
        authentication: :plain,
        enable_starttls_auto: true
      }
    else
      ActionMailer::Base.smtp_settings
    end
  end

  def signature_request(signer)
    @signer = signer
    @contract = signer.contract
    @sign_url = signer.sign_url

    mail(
      to: signer.email,
      subject: "Contrato para assinatura: #{@contract.title}",
      delivery_method: self.class.delivery_method,
      delivery_method_options: self.class.smtp_settings
    )
  end

  def signature_confirmation(signer)
    @signer = signer
    @contract = signer.contract
    @signature = signer.contract_signature

    # Anexar PDF se o contrato já está totalmente assinado
    if @contract.signed?
      begin
        pdf_data = @contract.generate_signed_pdf
        attachments["#{@contract.contract_number}.pdf"] = {
          mime_type: 'application/pdf',
          content: pdf_data
        }
      rescue StandardError => e
        Rails.logger.error "Erro ao gerar PDF para confirmação: #{e.message}"
      end
    end

    mail(
      to: signer.email,
      subject: "Contrato assinado com sucesso: #{@contract.title}",
      delivery_method: self.class.delivery_method,
      delivery_method_options: self.class.smtp_settings
    )
  end

  def signature_refused(signer)
    @signer = signer
    @contract = signer.contract
    @owner = @contract.created_by

    return unless @owner&.email.present?

    mail(
      to: @owner.email,
      subject: "Contrato recusado: #{@contract.title}",
      delivery_method: self.class.delivery_method,
      delivery_method_options: self.class.smtp_settings
    )
  end

  def contract_completed(contract)
    @contract = contract
    @signers = contract.contract_signers.signed
    @owner = contract.created_by

    return unless @owner&.email.present?

    begin
      pdf_data = contract.generate_signed_pdf
      attachments["#{contract.contract_number}-assinado.pdf"] = {
        mime_type: 'application/pdf',
        content: pdf_data
      }
    rescue StandardError => e
      Rails.logger.error "Erro ao gerar PDF para conclusão: #{e.message}"
    end

    # Enviar para o dono do contrato + signatários auto_sign (empresa)
    company_emails = contract.contract_signers.where(auto_sign: true).pluck(:email)
    recipients = ([@owner.email] + company_emails).uniq

    mail(
      to: recipients,
      subject: "Todas as assinaturas concluídas: #{@contract.title}",
      delivery_method: self.class.delivery_method,
      delivery_method_options: self.class.smtp_settings
    )
  end
end
