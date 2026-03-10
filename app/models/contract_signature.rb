# == Schema Information
#
# Table name: contract_signatures
#
#  id                   :bigint           not null, primary key
#  contract_signer_id   :bigint           not null
#  ip_address           :string
#  user_agent           :text
#  geolocation          :jsonb
#  signed_at            :datetime         not null
#  signature_hash       :string
#  browser_fingerprint  :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class ContractSignature < ApplicationRecord
  belongs_to :contract_signer

  # Delegações
  delegate :contract, to: :contract_signer

  # Validações
  validates :signed_at, presence: true

  # Callbacks
  before_create :generate_signature_hash

  # Scopes
  scope :recent, -> { order(signed_at: :desc) }

  # Gera hash único da assinatura para verificação
  def generate_signature_hash
    data = "#{contract_signer_id}|#{signed_at.iso8601}|#{ip_address}|#{user_agent}"
    self.signature_hash = Digest::SHA256.hexdigest(data)
  end

  # Verifica integridade da assinatura
  def valid_signature?
    expected = "#{contract_signer_id}|#{signed_at.iso8601}|#{ip_address}|#{user_agent}"
    signature_hash == Digest::SHA256.hexdigest(expected)
  end

  # Informações de localização formatadas
  def location_info
    return nil unless geolocation.present?

    parts = []
    parts << geolocation['city'] if geolocation['city'].present?
    parts << geolocation['region'] if geolocation['region'].present?
    parts << geolocation['country'] if geolocation['country'].present?
    parts.join(', ')
  end

  # Resumo das evidências para exibição
  def evidence_summary
    {
      ip: ip_address,
      location: location_info,
      device: parse_user_agent,
      timestamp: signed_at.iso8601,
      hash: signature_hash
    }
  end

  private

  def parse_user_agent
    return 'Desconhecido' unless user_agent.present?

    # Parse básico do user agent
    case user_agent
    when /Windows/
      'Windows'
    when /Mac OS X/
      'macOS'
    when /Linux/
      'Linux'
    when /Android/
      'Android'
    when /iPhone|iPad/
      'iOS'
    else
      'Outro'
    end
  end
end
