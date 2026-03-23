# frozen_string_literal: true

# Controller público para assinatura de contratos (sem autenticação)
# Renderiza a página HTML onde o signatário visualiza e assina o contrato.
# As ações de assinar/recusar são processadas via API pública (Public::Api::V1::ContractsController).
class ContractsController < ActionController::Base
  layout false

  before_action :set_signer
  before_action :check_signer_status

  # GET /contracts/sign/:token
  def sign
    @contract = @signer.contract
    @token = params[:token]
    @signer.mark_as_viewed!(request.remote_ip)
    render 'contracts/sign'
  end

  private

  def set_signer
    @signer = ContractSigner.find_by(sign_token: params[:token])

    unless @signer
      render plain: 'Link inválido ou expirado.', status: :not_found
    end
  end

  def check_signer_status
    return unless @signer
    return if @signer.can_sign?

    # Se já assinou ou recusou, ainda mostra a página (com o status correto)
    @contract = @signer.contract
    @token = params[:token]
    render 'contracts/sign'
  end
end
