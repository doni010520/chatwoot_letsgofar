# frozen_string_literal: true

# == Schema Information
#
# Table name: contract_signers
#
#  id              :bigint           not null, primary key
#  contract_id     :bigint           not null
#  name            :string           not null
#  email           :string           not null
#  role            :string           default("contractor")
#  sign_token      :string           not null
#  status          :string           default("pending")
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

  # Roles possíveis
  ROLES = %w[contractor contracted witness].freeze

  # Status possíveis
  STATUSES = %w[pending viewed signed refused].freeze

  # Validações
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :sign_token, presence: true, uniqueness: true

  # Scopes
  scope :pending, -> { where(status: %w[pending viewed]) }
  scope :signed, -> { where(status: 'signed') }
  scope :refused, -> { where(status: 'refused') }

  # Callbacks
  before_validation :generate_sign_token, on: :create

  # Gerar token de assinatura
  def generate_sign_token
    self.sign_token ||= SecureRandom.uuid
  end

  # Regenerar token
  def regenerate_token!
    update!(sign_token: SecureRandom.uuid)
  end

  # Status helpers
  def pending?
    status == 'pending'
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

  # Verificar se pode assinar
  def can_sign?
    %w[pending viewed].include?(status)
  end

  # Marcar como visualizado
  def mark_as_viewed!
    return unless pending?

    update!(
      status: 'viewed',
      viewed_at: Time.current
    )

    contract.contract_activities.create!(
      activity_type: 'viewed',
      contract_signer: self,
      description: "#{name} visualizou o contrato"
    )
  end

  # Assinar contrato
  def sign!(signature_data = {})
    return false unless can_sign?

    transaction do
      update!(
        status: 'signed',
        signed_at: Time.current
      )

      # Criar registro de assinatura com evidências
      create_contract_signature!(
        ip_address: signature_data[:ip_address],
        user_agent: signature_data[:user_agent],
        geolocation: signature_data[:geolocation],
        signed_at: Time.current,
        signature_hash: generate_signature_hash(signature_data),
        browser_fingerprint: signature_data[:browser_fingerprint],
        metadata: signature_data[:metadata] || {}
      )

      contract.contract_activities.create!(
        activity_type: 'signed',
        contract_signer: self,
        description: "#{name} assinou o contrato"
      )

      # Atualizar status do contrato
      contract.update_signature_status!
    end

    true
  end

  # Recusar contrato
  def refuse!(reason = nil)
    return false unless can_sign?

    transaction do
      update!(
        status: 'refused',
        refused_at: Time.current,
        refusal_reason: reason
      )

      contract.contract_activities.create!(
        activity_type: 'refused',
        contract_signer: self,
        description: "#{name} recusou o contrato#{reason.present? ? ": #{reason}" : ''}"
      )

      # Atualizar status do contrato
      contract.update_signature_status!
    end

    true
  end

  # URL pública para assinatura
  def signature_url
    # Rota da página de assinatura
    "/contracts/sign/#{sign_token}"
  end

  # Label do role em português
  def role_label
    case role
    when 'contractor' then 'Contratante'
    when 'contracted' then 'Contratada'
    when 'witness' then 'Testemunha'
    else role
    end
  end

  private

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
