# frozen_string_literal: true

class Api::V1::Accounts::ContractsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_contract, only: [:show, :update, :destroy, :send_for_signature, :cancel, :duplicate, :download_pdf, :resend_to_signer]

  def index
    @contracts = Current.account.contracts
                        .includes(:contract_signers, :created_by, :contact)
                        .order(created_at: :desc)

    # Filtros
    @contracts = @contracts.where(status: params[:status]) if params[:status].present?
    @contracts = @contracts.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    @contracts = @contracts.where(created_by_id: params[:created_by_id]) if params[:created_by_id].present?
    
    # Filtro por data
    @contracts = @contracts.where('created_at >= ?', params[:date_from].to_date.beginning_of_day) if params[:date_from].present?
    @contracts = @contracts.where('created_at <= ?', params[:date_to].to_date.end_of_day) if params[:date_to].present?

    # Busca por texto
    if params[:q].present?
      search_term = "%#{params[:q].downcase}%"
      @contracts = @contracts.where(
        'LOWER(title) LIKE :q OR LOWER(contract_number) LIKE :q OR LOWER(contractor_name) LIKE :q OR LOWER(contractor_email) LIKE :q',
        q: search_term
      )
    end

    # Ordenação
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    allowed_sort_fields = %w[created_at title status sent_at signed_at]
    sort_by = 'created_at' unless allowed_sort_fields.include?(sort_by)
    @contracts = @contracts.order("#{sort_by} #{sort_order}")

    # Paginação
    @contracts = @contracts.page(params[:page] || 1).per(params[:per_page] || 20)

    render json: {
      data: @contracts.map { |c| contract_json(c) },
      meta: {
        total_count: @contracts.total_count,
        total_pages: @contracts.total_pages,
        current_page: @contracts.current_page
      }
    }
  end

  def show
    render json: { data: contract_json(@contract, full: true) }
  end

  def create
    @contract = Current.account.contracts.new(contract_params)
    @contract.created_by = Current.user

    if @contract.save
      render json: { data: contract_json(@contract, full: true) }, status: :created
    else
      render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    unless @contract.editable?
      render json: { error: 'Contrato não pode ser editado neste status' }, status: :unprocessable_entity
      return
    end

    if @contract.update(contract_params)
      @contract.contract_activities.create!(
        activity_type: 'edited',
        user: Current.user,
        description: 'Contrato editado'
      )
      render json: { data: contract_json(@contract, full: true) }
    else
      render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless @contract.draft?
      render json: { error: 'Apenas rascunhos podem ser excluídos' }, status: :unprocessable_entity
      return
    end

    @contract.destroy!
    head :no_content
  end

  def send_for_signature
    unless @contract.can_send?
      render json: { error: 'Contrato não pode ser enviado para assinatura' }, status: :unprocessable_entity
      return
    end

    if @contract.send_for_signature!(Current.user)
      render json: { data: contract_json(@contract, full: true), message: 'Contrato enviado para assinatura' }
    else
      render json: { error: 'Erro ao enviar contrato' }, status: :unprocessable_entity
    end
  end

  def cancel
    unless @contract.can_cancel?
      render json: { error: 'Contrato não pode ser cancelado' }, status: :unprocessable_entity
      return
    end

    if @contract.cancel!(Current.user, params[:reason])
      render json: { data: contract_json(@contract, full: true), message: 'Contrato cancelado' }
    else
      render json: { error: 'Erro ao cancelar contrato' }, status: :unprocessable_entity
    end
  end

  def duplicate
    new_contract = @contract.duplicate!(Current.user)
    render json: { data: contract_json(new_contract, full: true), message: 'Contrato duplicado' }, status: :created
  end

  def resend_to_signer
    signer = @contract.contract_signers.find(params[:signer_id])
    
    unless signer.can_sign?
      render json: { error: 'Signatário já assinou ou recusou' }, status: :unprocessable_entity
      return
    end

    ContractMailer.signature_request(signer).deliver_later

    @contract.contract_activities.create!(
      activity_type: 'reminder_sent',
      user: Current.user,
      contract_signer: signer,
      description: "Lembrete enviado para #{signer.name}"
    )

    render json: { message: 'Lembrete enviado com sucesso' }
  end

  def download_pdf
    pdf_data = @contract.generate_signed_pdf
    send_data pdf_data,
              filename: "#{@contract.contract_number}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  def expiring
    contracts = Current.account.contracts
                       .signed
                       .where('plan_end_date BETWEEN ? AND ?', Date.current, 30.days.from_now)
                       .order(:plan_end_date)
                       .includes(:contract_signers, :contact)

    render json: {
      data: contracts.map { |c| contract_json(c) }
    }
  end

  def stats
    contracts = Current.account.contracts

    render json: {
      total: contracts.count,
      draft: contracts.draft.count,
      pending: contracts.pending.count,
      signed: contracts.signed.count,
      refused: contracts.refused.count,
      expired: contracts.expired.count,
      cancelled: contracts.cancelled.count,
      this_month: contracts.where('created_at >= ?', Time.current.beginning_of_month).count,
      signed_this_month: contracts.signed.where('signed_at >= ?', Time.current.beginning_of_month).count,
      expiring_30_days: contracts.signed.where('plan_end_date BETWEEN ? AND ?', Date.current, 30.days.from_now).count,
      expired_plans: contracts.signed.where('plan_end_date < ?', Date.current).count
    }
  end

  private

  def set_contract
    @contract = Current.account.contracts.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(
      :title,
      :content_html,
      :contact_id,
      :contract_template_id,
      :expires_at,
      :plan_start_date,
      :plan_end_date,
      # Dados do contratante
      :contractor_name,
      :contractor_cpf,
      :contractor_rg,
      :contractor_address,
      :contractor_neighborhood,
      :contractor_city,
      :contractor_cep,
      :contractor_state,
      :contractor_email,
      :contractor_phone,
      :contractor_birth_date,
      # Dados do plano
      :plan_name,
      :plan_duration,
      :sessions_call_estrategica,
      :sessions_individual,
      :sessions_group_consultive,
      :sessions_group_meetings,
      :plan_value,
      :installments_count,
      :first_installment_value,
      :installment_due_day,
      # Metadados e variáveis
      metadata: {},
      variables: {},
      # Signatários aninhados
      contract_signers_attributes: [:id, :name, :email, :cpf, :role, :sign_order, :_destroy]
    )
  end

  def contract_json(contract, full: false)
    data = {
      id: contract.id,
      title: contract.title,
      contract_number: contract.contract_number,
      status: contract.status,
      created_at: contract.created_at,
      sent_at: contract.sent_at,
      signed_at: contract.signed_at,
      expires_at: contract.expires_at,
      contractor_name: contract.contractor_name,
      contractor_email: contract.contractor_email,
      plan_name: contract.plan_name,
      plan_value: contract.plan_value,
      plan_start_date: contract.plan_start_date,
      plan_end_date: contract.plan_end_date,
      signature_progress: contract.signature_progress,
      created_by: contract.created_by ? {
        id: contract.created_by.id,
        name: contract.created_by.display_name || contract.created_by.name
      } : nil
    }

    if full
      data.merge!(
        content_html: contract.content_html,
        document_hash: contract.document_hash,
        variables: contract.variables,
        contact_id: contract.contact_id,
        contract_template_id: contract.contract_template_id,
        cancelled_at: contract.cancelled_at,
        # Todos os dados do contratante
        contractor_cpf: contract.contractor_cpf,
        contractor_rg: contract.contractor_rg,
        contractor_address: contract.contractor_address,
        contractor_neighborhood: contract.contractor_neighborhood,
        contractor_city: contract.contractor_city,
        contractor_cep: contract.contractor_cep,
        contractor_state: contract.contractor_state,
        contractor_phone: contract.contractor_phone,
        contractor_birth_date: contract.contractor_birth_date,
        # Todos os dados do plano
        plan_duration: contract.plan_duration,
        sessions_call_estrategica: contract.sessions_call_estrategica,
        sessions_individual: contract.sessions_individual,
        sessions_group_consultive: contract.sessions_group_consultive,
        sessions_group_meetings: contract.sessions_group_meetings,
        installments_count: contract.installments_count,
        first_installment_value: contract.first_installment_value,
        installment_due_day: contract.installment_due_day,
        metadata: contract.metadata,
        # Relacionamentos
        signers: contract.contract_signers.map { |s| signer_json(s) },
        activities: contract.contract_activities.recent.limit(50).map { |a| activity_json(a) }
      )
    else
      data[:signers_count] = contract.contract_signers.count
    end

    data
  end

  def signer_json(signer)
    {
      id: signer.id,
      name: signer.name,
      email: signer.email,
      role: signer.role,
      role_label: signer.role_label,
      status: signer.status,
      sign_token: signer.sign_token,
      signature_url: signer.signature_url,
      viewed_at: signer.viewed_at,
      signed_at: signer.signed_at,
      refused_at: signer.refused_at,
      refusal_reason: signer.refusal_reason,
      signature: signer.contract_signature ? {
        ip_address: signer.contract_signature.ip_address,
        signed_at: signer.contract_signature.signed_at,
        signature_hash: signer.contract_signature.signature_hash
      } : nil
    }
  end

  def activity_json(activity)
    {
      id: activity.id,
      type: activity.activity_type,
      type_label: activity.type_label,
      description: activity.description,
      icon: activity.icon,
      color: activity.color,
      author: activity.author_name,
      created_at: activity.created_at
    }
  end
end
