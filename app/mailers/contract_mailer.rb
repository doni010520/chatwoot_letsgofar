# frozen_string_literal: true

class ContractMailer < ApplicationMailer
  default from: ENV.fetch('CONTRACT_MAILER_FROM', 'Let\'s Go Far Contratos <contratos@benitechlab.com>')
  layout 'mailer/contract'

  RESEND_SMTP = {
    address: 'smtp.resend.com',
    port: 465,
    user_name: 'resend',
    password: ENV.fetch('RESEND_API_KEY', ''),
    authentication: :plain,
    ssl: true
  }.freeze

  def signature_request(signer)
    @signer = signer
    @contract = signer.contract
    @sign_url = signer.sign_url

    mail(
      to: signer.email,
      subject: "Contrato para assinatura: #{@contract.title}",
      **resend_options
    )
  end

  def signature_confirmation(signer)
    @signer = signer
    @contract = signer.contract
    @signature = signer.contract_signature

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
      **resend_options
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
      **resend_options
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

    company_emails = contract.contract_signers.where(auto_sign: true).pluck(:email)
    recipients = ([@owner.email] + company_emails).uniq

    mail(
      to: recipients,
      subject: "Todas as assinaturas concluídas: #{@contract.title}",
      **resend_options
    )
  end

  private

  def resend_options
    if ENV['RESEND_API_KEY'].present?
      { delivery_method: :smtp, delivery_method_options: RESEND_SMTP }
    else
      {}
    end
  end
end
