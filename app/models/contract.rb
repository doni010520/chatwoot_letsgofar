# frozen_string_literal: true

# == Schema Information
#
# Table name: contracts
#
#  id                       :bigint           not null, primary key
#  account_id               :bigint           not null
#  contact_id               :bigint
#  created_by_id            :bigint
#  title                    :string           not null
#  contract_number          :string           not null
#  content_html             :text
#  document_hash            :string
#  status                   :string           default("draft")
#  sent_at                  :datetime
#  signed_at                :datetime
#  expires_at               :datetime
#  cancelled_at             :datetime
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

  has_many :contract_signers, dependent: :destroy
  has_many :contract_activities, dependent: :destroy

  # Aceita atributos aninhados para signatários
  accepts_nested_attributes_for :contract_signers, allow_destroy: true

  # Status possíveis
  STATUSES = %w[draft pending partially_signed signed refused expired cancelled].freeze

  # Validações
  validates :title, presence: true
  validates :contract_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :draft, -> { where(status: 'draft') }
  scope :pending, -> { where(status: %w[pending partially_signed]) }
  scope :signed, -> { where(status: 'signed') }
  scope :refused, -> { where(status: 'refused') }
  scope :expired, -> { where(status: 'expired') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :active, -> { where.not(status: %w[cancelled expired]) }

  # Callbacks
  before_validation :generate_contract_number, on: :create
  before_save :generate_document_hash, if: :content_html_changed?
  after_create :log_creation

  # Gerar número do contrato
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

  # Gerar hash do documento
  def generate_document_hash
    return unless content_html.present?

    self.document_hash = Digest::SHA256.hexdigest(content_html)
  end

  # Verificar se pode ser editado
  def editable?
    draft?
  end

  # Verificar se pode ser enviado
  def can_send?
    draft? && contract_signers.any?
  end

  # Verificar se pode ser cancelado
  def can_cancel?
    %w[draft pending partially_signed].include?(status)
  end

  # Status helpers
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

  # Enviar para assinatura
  def send_for_signature!(user = nil)
    return false unless can_send?

    transaction do
      update!(
        status: 'pending',
        sent_at: Time.current,
        expires_at: 30.days.from_now
      )

      contract_signers.each do |signer|
        signer.regenerate_token! if signer.sign_token.blank?
        # TODO: Enviar email para cada signatário
        # ContractMailer.signature_request(signer).deliver_later
      end

      log_activity('sent', user, 'Contrato enviado para assinatura')
    end

    true
  end

  # Atualizar status baseado nas assinaturas
  def update_signature_status!
    return if cancelled? || expired?

    signers = contract_signers.reload
    
    if signers.any?(&:refused?)
      update!(status: 'refused')
      log_activity('refused', nil, 'Contrato recusado por um dos signatários')
    elsif signers.all?(&:signed?)
      update!(status: 'signed', signed_at: Time.current)
      log_activity('signed', nil, 'Todas as assinaturas foram coletadas')
    elsif signers.any?(&:signed?)
      update!(status: 'partially_signed')
    end
  end

  # Cancelar contrato
  def cancel!(user = nil, reason = nil)
    return false unless can_cancel?

    update!(
      status: 'cancelled',
      cancelled_at: Time.current
    )

    log_activity('cancelled', user, reason || 'Contrato cancelado')
    true
  end

  # Verificar expiração
  def check_expiration!
    return unless pending? || partially_signed?
    return unless expires_at.present? && expires_at < Time.current

    update!(status: 'expired')
    log_activity('expired', nil, 'Contrato expirou')
  end

  # Duplicar contrato
  def duplicate!(user = nil)
    new_contract = dup
    new_contract.contract_number = nil
    new_contract.status = 'draft'
    new_contract.sent_at = nil
    new_contract.signed_at = nil
    new_contract.expires_at = nil
    new_contract.cancelled_at = nil
    new_contract.document_hash = nil
    new_contract.created_by = user
    new_contract.title = "#{title} (Cópia)"
    
    new_contract.save!
    new_contract
  end

  # Progresso das assinaturas
  def signature_progress
    total = contract_signers.count
    signed = contract_signers.signed.count
    
    {
      total: total,
      signed: signed,
      pending: total - signed,
      percentage: total.positive? ? (signed.to_f / total * 100).round : 0
    }
  end

  private

  def log_creation
    log_activity('created', created_by, 'Contrato criado')
  end

  def log_activity(activity_type, user = nil, description = nil)
    contract_activities.create!(
      activity_type: activity_type,
      user: user,
      description: description
    )
  end
end
