# frozen_string_literal: true

# == Schema Information
#
# Table name: contracts
#
#  id                       :bigint           not null, primary key
#  account_id               :bigint           not null
#  contact_id               :bigint
#  created_by_id            :bigint
#  contract_template_id     :bigint
#  title                    :string           not null
#  contract_number          :string           not null
#  content_html             :text
#  document_hash            :string
#  status                   :string           default("draft")
#  variables                :jsonb            default({})
#  sent_at                  :datetime
#  signed_at                :datetime
#  expires_at               :datetime
#  cancelled_at             :datetime
#  plan_start_date          :date
#  plan_end_date            :date
#  contractor_*             :string           (dados do contratante)
#  plan_*                   :varies           (dados do plano)
#  metadata                 :jsonb
#  created_at               :datetime
#  updated_at               :datetime
#
class Contract < ApplicationRecord
  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :contract_template, optional: true

  has_many :contract_signers, dependent: :destroy
  has_many :contract_activities, dependent: :destroy

  has_one_attached :signed_pdf

  # Aceita atributos aninhados para signatários
  accepts_nested_attributes_for :contract_signers, allow_destroy: true

  # Signatária fixa da empresa (auto-sign)
  COMPANY_SIGNER = {
    name: 'Ianka Cavalcante',
    email: 'letsgofaridioma@gmail.com',
    role: 'company'
  }.freeze

  # Status possíveis
  STATUSES = %w[draft pending partially_signed signed refused expired cancelled].freeze

  # Validações
  validates :title, presence: true
  validates :contract_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :content_html, length: { maximum: 150_000 }

  # Scopes de status
  scope :draft, -> { where(status: 'draft') }
  scope :pending, -> { where(status: %w[pending partially_signed]) }
  scope :signed, -> { where(status: 'signed') }
  scope :refused, -> { where(status: 'refused') }
  scope :expired, -> { where(status: 'expired') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :active, -> { where.not(status: %w[cancelled expired]) }

  # Scopes para controle de renovação (baseado em plan_end_date)
  scope :expiring_this_month, -> { where(plan_end_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :expiring_next_month, -> { where(plan_end_date: Date.current.next_month.beginning_of_month..Date.current.next_month.end_of_month) }
  scope :expiring_in_days, ->(days) { where(plan_end_date: Date.current..(Date.current + days.days)) }
  scope :expired_plans, -> { where('plan_end_date < ?', Date.current) }
  scope :active_plans, -> { where('plan_end_date >= ?', Date.current) }

  # Callbacks
  before_validation :generate_contract_number, on: :create
  before_save :generate_document_hash, if: :content_html_changed?
  before_save :extract_plan_dates_from_variables
  after_create :add_company_signer
  after_create :log_creation

  # === Status helpers ===

  def draft?
    status == 'draft'
  end

  def pending?
    status == 'pending'
  end

  def partially_signed?
    status == 'partially_signed'
  end

  def signed?
    status == 'signed'
  end

  def refused?
    status == 'refused'
  end

  def expired?
    status == 'expired'
  end

  def cancelled?
    status == 'cancelled'
  end

  def status_label
    {
      'draft' => 'Rascunho',
      'pending' => 'Aguardando Assinatura',
      'partially_signed' => 'Parcialmente Assinado',
      'signed' => 'Assinado',
      'refused' => 'Recusado',
      'expired' => 'Expirado',
      'cancelled' => 'Cancelado'
    }[status] || status
  end

  def status_color
    {
      'draft' => 'gray',
      'pending' => 'yellow',
      'partially_signed' => 'blue',
      'signed' => 'green',
      'refused' => 'red',
      'expired' => 'orange',
      'cancelled' => 'gray'
    }[status] || 'gray'
  end

  # === Verificações ===

  def editable?
    draft?
  end

  def can_send?
    draft? && contract_signers.where(auto_sign: false).any?
  end

  def can_cancel?
    %w[draft pending partially_signed].include?(status)
  end

  # === Ações ===

  def send_for_signature!(user = nil)
    return false unless can_send?

    update!(
      status: 'pending',
      sent_at: Time.current,
      expires_at: 30.days.from_now
    )

    # Envia emails para signatários manuais
    contract_signers.pending.where(auto_sign: false).each do |signer|
      ContractMailer.signature_request(signer).deliver_later
    end

    # Auto-assina os signatários automáticos (empresa)
    contract_signers.pending.where(auto_sign: true).each do |signer|
      signer.sign!({
        ip_address: '127.0.0.1',
        user_agent: 'AutoSign/1.0 (Let\'s Go Far)',
        geolocation: {},
        browser_fingerprint: 'auto_sign',
        confirmation_name: signer.name,
        confirmation_cpf: signer.cpf
      })
    rescue StandardError => e
      Rails.logger.error "Erro no auto-sign de #{signer.name}: #{e.message}"
    end

    log_activity!('sent', user: user, metadata: { signers_count: contract_signers.count })
    true
  end

  def update_signature_status!
    return if status.in?(%w[signed refused cancelled expired])

    signers = contract_signers.reload

    if signers.any?(&:refused?)
      update!(status: 'refused')
      log_activity!('refused')
    elsif signers.all?(&:signed?)
      update!(status: 'signed', signed_at: Time.current)
      log_activity!('completed')
      generate_and_attach_pdf!
      begin
        ContractMailer.contract_completed(self).deliver_later
      rescue StandardError => e
        Rails.logger.error "Erro ao enviar email de conclusão: #{e.message}"
      end
    elsif signers.any?(&:signed?)
      update!(status: 'partially_signed')
    end
  end

  def cancel!(user = nil, reason = nil)
    return false unless can_cancel?

    update!(
      status: 'cancelled',
      cancelled_at: Time.current
    )

    log_activity!('cancelled', user: user, metadata: { reason: reason })
    true
  end

  def check_expiration!
    return unless pending? || partially_signed?
    return unless expires_at.present? && expires_at < Time.current

    update!(status: 'expired')
    log_activity!('expired')
  end

  def duplicate!(user = nil)
    new_contract = dup
    new_contract.contract_number = nil
    new_contract.status = 'draft'
    new_contract.sent_at = nil
    new_contract.signed_at = nil
    new_contract.expires_at = nil
    new_contract.cancelled_at = nil
    new_contract.document_hash = nil
    new_contract.created_by = user || created_by
    new_contract.title = "#{title} (Cópia)"
    new_contract.save!

    # Copia apenas signatários manuais (company signer é adicionado via callback)
    contract_signers.where(auto_sign: false).each do |signer|
      new_contract.contract_signers.create!(
        name: signer.name,
        email: signer.email,
        cpf: signer.cpf,
        role: signer.role,
        sign_order: signer.sign_order
      )
    end

    new_contract
  end

  # Gera PDF do contrato assinado
  def generate_signed_pdf
    html = ApplicationController.render(
      template: 'contracts/preview',
      layout: 'pdf',
      assigns: { contract: self }
    )

    WickedPdf.new.pdf_from_string(html, encoding: 'UTF-8')
  end

  # Progresso das assinaturas
  def signature_progress
    total = contract_signers.count
    signed_count = contract_signers.signed.count

    {
      total: total,
      signed: signed_count,
      pending: total - signed_count,
      percentage: total.positive? ? (signed_count.to_f / total * 100).round : 0
    }
  end

  # Nome do contratante (a partir das variáveis ou do primeiro signatário)
  def contractor_name
    variables&.dig('contractor_name') || contract_signers.where.not(role: 'company').first&.name
  end

  def push_event_data
    {
      id: id,
      title: title,
      contract_number: contract_number,
      status: status,
      plan_end_date: plan_end_date,
      contractor_name: contractor_name
    }
  end

  # Log de atividade
  def log_activity!(activity_type, user: nil, signer: nil, metadata: {}, ip_address: nil)
    contract_activities.create!(
      activity_type: activity_type,
      user: user,
      contract_signer: signer,
      metadata: metadata,
      ip_address: ip_address
    )
  end

  private

  def add_company_signer
    contract_signers.create!(
      name: COMPANY_SIGNER[:name],
      email: COMPANY_SIGNER[:email],
      role: COMPANY_SIGNER[:role],
      auto_sign: true,
      sign_order: 0
    )
  rescue StandardError => e
    Rails.logger.error "Erro ao adicionar signatária da empresa: #{e.message}"
  end

  def generate_contract_number
    return if contract_number.present?

    year = Time.current.year
    last_contract = account.contracts.where('contract_number LIKE ?', "CTR-#{year}-%").order(:contract_number).last

    if last_contract
      last_number = last_contract.contract_number.split('-').last.to_i
      self.contract_number = "CTR-#{year}-#{(last_number + 1).to_s.rjust(5, '0')}"
    else
      self.contract_number = "CTR-#{year}-00001"
    end
  end

  def generate_document_hash
    return unless content_html.present?

    self.document_hash = Digest::SHA256.hexdigest("#{contract_number}|#{content_html}|#{Time.current.to_i}")
  end

  def extract_plan_dates_from_variables
    return unless variables.present?

    if variables['plan_start_date'].present?
      self.plan_start_date = parse_flexible_date(variables['plan_start_date'])
    end

    if variables['plan_end_date'].present?
      self.plan_end_date = parse_flexible_date(variables['plan_end_date'])

      # Substitui no HTML se ainda não foi substituído
      if plan_end_date.present? && content_html.present? && content_html.include?('{{plan_end_date}}')
        self.content_html = content_html.gsub('{{plan_end_date}}', plan_end_date.strftime('%d/%m/%Y'))
      end
    end
  end

  def parse_flexible_date(date_string)
    return nil if date_string.blank?

    if date_string.match?(%r{\A\d{2}/\d{2}/\d{4}\z})
      Date.strptime(date_string, '%d/%m/%Y')
    elsif date_string.match?(%r{\A\d{4}-\d{2}-\d{2}\z})
      Date.parse(date_string)
    else
      Date.parse(date_string)
    end
  rescue Date::Error, ArgumentError
    nil
  end

  def generate_and_attach_pdf!
    pdf_data = generate_signed_pdf
    signed_pdf.attach(
      io: StringIO.new(pdf_data),
      filename: "#{contract_number}_assinado.pdf",
      content_type: 'application/pdf'
    )
  rescue StandardError => e
    Rails.logger.error "Erro ao gerar PDF assinado para contrato #{contract_number}: #{e.message}"
  end

  def log_creation
    log_activity!('created', user: created_by)
  end
end
