# frozen_string_literal: true

# == Schema Information
#
# Table name: contract_signers
#
#  id              :bigint           not null, primary key
#  contract_id     :bigint           not null
#  name            :string           not null
#  email           :string           not null
#  cpf             :string
#  role            :string           default("contractor")
#  sign_token      :string           not null
#  status          :string           default("pending")
#  sign_order      :integer          default(1)
#  auto_sign       :boolean          default(false)
#  viewed_at       :datetime
#  signed_at       :datetime
#  refused_at      :datetime
#  refusal_reason  :text
#  created_at      :datetime
#  updated_at      :datetime
#
class ContractSigner < ApplicationRecord
  belongs_to :contract
  has_one :contract_signature, dependent: :destroy
  has_many :contract_activities, class_name: 'ContractActivity', dependent: :nullify

  # Roles possíveis
  ROLES = %w[contractor contracted witness company].freeze

  # Status possíveis
  STATUSES = %w[pending viewed signed refused].freeze

  # Validações
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :contract_id, message: 'já adicionado neste contrato' }
  validates :sign_token, presence: true, uniqueness: true

  # Scopes
  scope :pending, -> { where(status: %w[pending viewed]) }
  scope :signed, -> { where(status: 'signed') }
  scope :refused, -> { where(status: 'refused') }
  scope :by_order, -> { order(:sign_order) }

  # Callbacks
  before_validation :generate_sign_token, on: :create

  # === Status helpers ===

  def pending?
    %w[pending viewed].include?(status)
  end

  def viewed?
    status == 'viewed'
  end

  def signed?
    status == 'signed'
  end

  def refused?
    status == 'refused'
  end

  def auto_sign?
    auto_sign == true
  end

  def can_sign?
    %w[pending viewed].include?(status)
  end

  # === Ações ===

  def mark_as_viewed!(ip_address = nil)
    return if viewed_at.present?

    update!(viewed_at: Time.current)

    contract.log_activity!(
      'viewed',
      signer: self,
      ip_address: ip_address,
      metadata: { signer_name: name }
    )
  end

  def sign!(signature_data = {})
    return false unless can_sign?

    transaction do
      create_contract_signature!(
        ip_address: signature_data[:ip_address],
        user_agent: signature_data[:user_agent],
        geolocation: signature_data[:geolocation] || {},
        signed_at: Time.current,
        signature_hash: generate_signature_hash(signature_data),
        browser_fingerprint: signature_data[:browser_fingerprint],
        confirmation_name: signature_data[:confirmation_name],
        confirmation_cpf: signature_data[:confirmation_cpf]
      )

      update!(status: 'signed', signed_at: Time.current)

      contract.log_activity!(
        'signed',
        signer: self,
        ip_address: signature_data[:ip_address],
        metadata: { signer_name: name, signer_email: email }
      )

      contract.update_signature_status!

      # Enviar confirmação (exceto para assinaturas automáticas)
      unless auto_sign?
        ContractMailer.signature_confirmation(self).deliver_later
      end
    end

    true
  rescue StandardError => e
    Rails.logger.error "Erro ao assinar contrato: #{e.message}"
    false
  end

  def refuse!(reason = nil, ip_address = nil)
    return false unless can_sign?

    update!(
      status: 'refused',
      refused_at: Time.current,
      refusal_reason: reason
    )

    contract.log_activity!(
      'refused',
      signer: self,
      ip_address: ip_address,
      metadata: { signer_name: name, reason: reason }
    )

    contract.update_signature_status!

    # Notificar criador do contrato
    ContractMailer.signature_refused(self).deliver_later

    true
  end

  # URL pública para assinatura
  def sign_url
    host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    "#{host}/contracts/sign/#{sign_token}"
  end

  def signature_url
    sign_url
  end

  # Regenerar token
  def regenerate_token!
    generate_sign_token
    save!
  end

  # Label do role em português
  def role_label
    {
      'contractor' => 'Contratante',
      'contracted' => 'Contratada',
      'witness' => 'Testemunha',
      'company' => 'Empresa'
    }[role] || role
  end

  def status_label
    {
      'pending' => 'Pendente',
      'viewed' => 'Visualizado',
      'signed' => 'Assinado',
      'refused' => 'Recusado'
    }[status] || status
  end

  private

  def generate_sign_token
    self.sign_token = SecureRandom.urlsafe_base64(32)
  end

  def generate_signature_hash(data)
    content = [
      contract.document_hash,
      email,
      data[:ip_address],
      Time.current.utc.iso8601
    ].join('|')

    Digest::SHA256.hexdigest(content)
  end
end
