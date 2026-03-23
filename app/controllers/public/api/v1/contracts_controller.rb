# frozen_string_literal: true

class Public::Api::V1::ContractsController < PublicController
  before_action :set_signer_by_token
  before_action :check_contract_status, only: [:sign, :refuse]

  # GET /public/api/v1/contracts/:token
  # Retorna dados do contrato para visualização pública
  def show
    # Marca como visualizado se ainda não foi
    @signer.mark_as_viewed! if @signer.pending?

    render json: {
      data: {
        contract: {
          id: @contract.id,
          title: @contract.title,
          contract_number: @contract.contract_number,
          content_html: @contract.content_html,
          status: @contract.status,
          expires_at: @contract.expires_at,
          contractor_name: @contract.contractor_name
        },
        signer: {
          id: @signer.id,
          name: @signer.name,
          email: @signer.email,
          role: @signer.role,
          role_label: @signer.role_label,
          status: @signer.status,
          can_sign: @signer.can_sign?,
          signed_at: @signer.signed_at,
          refused_at: @signer.refused_at
        }
      }
    }
  end

  # POST /public/api/v1/contracts/:token/sign
  # Registra a assinatura do contrato
  def sign
    unless @signer.can_sign?
      render json: { error: 'Este contrato já foi assinado ou recusado' }, status: :unprocessable_entity
      return
    end

    # Validar aceite dos termos
    unless params[:accept_terms] == true || params[:accept_terms] == 'true'
      render json: { error: 'Você deve aceitar os termos do contrato' }, status: :unprocessable_entity
      return
    end

    # Capturar evidências
    signature_data = {
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      geolocation: params[:geolocation],
      browser_fingerprint: params[:browser_fingerprint],
      metadata: {
        name_confirmation: params[:name_confirmation],
        cpf_confirmation: params[:cpf_confirmation],
        accepted_at: Time.current.utc.iso8601
      }
    }

    if @signer.sign!(signature_data)
      render json: {
        message: 'Contrato assinado com sucesso',
        data: {
          signed_at: @signer.signed_at,
          signature_hash: @signer.contract_signature&.signature_hash
        }
      }
    else
      render json: { error: 'Erro ao assinar o contrato' }, status: :unprocessable_entity
    end
  end

  # POST /public/api/v1/contracts/:token/refuse
  # Registra a recusa do contrato
  def refuse
    unless @signer.can_sign?
      render json: { error: 'Este contrato já foi assinado ou recusado' }, status: :unprocessable_entity
      return
    end

    if @signer.refuse!(params[:reason])
      render json: {
        message: 'Contrato recusado',
        data: {
          refused_at: @signer.refused_at
        }
      }
    else
      render json: { error: 'Erro ao recusar o contrato' }, status: :unprocessable_entity
    end
  end

  # GET /public/api/v1/contracts/:token/download
  # Download do contrato em PDF
  def download
    pdf_data = @contract.generate_signed_pdf
    send_data pdf_data,
              filename: "#{@contract.contract_number}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  private

  def set_signer_by_token
    @signer = ContractSigner.find_by(sign_token: params[:token])

    unless @signer
      render json: { error: 'Contrato não encontrado' }, status: :not_found
      return
    end

    @contract = @signer.contract
  end

  def check_contract_status
    if @contract.cancelled?
      render json: { error: 'Este contrato foi cancelado' }, status: :gone
      return
    end

    if @contract.expires_at.present? && @contract.expires_at < Time.current
      @contract.check_expiration!
      render json: { error: 'Este contrato expirou' }, status: :gone
      return
    end
  end
end
