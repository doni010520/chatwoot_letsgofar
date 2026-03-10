# frozen_string_literal: true

# == Schema Information
#
# Table name: contract_activities
#
#  id                 :bigint           not null, primary key
#  contract_id        :bigint           not null
#  user_id            :bigint
#  contract_signer_id :bigint
#  activity_type      :string           not null
#  description        :text
#  metadata           :jsonb
#  created_at         :datetime
#  updated_at         :datetime
#
class ContractActivity < ApplicationRecord
  belongs_to :contract
  belongs_to :user, optional: true
  belongs_to :contract_signer, optional: true

  # Tipos de atividade
  ACTIVITY_TYPES = %w[
    created
    edited
    sent
    viewed
    signed
    refused
    expired
    cancelled
    reminder_sent
  ].freeze

  # Validações
  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }

  # Ícone para cada tipo de atividade
  def icon
    case activity_type
    when 'created' then 'file-plus'
    when 'edited' then 'edit'
    when 'sent' then 'send'
    when 'viewed' then 'eye'
    when 'signed' then 'check-circle'
    when 'refused' then 'x-circle'
    when 'expired' then 'clock'
    when 'cancelled' then 'x-square'
    when 'reminder_sent' then 'bell'
    else 'activity'
    end
  end

  # Cor para cada tipo de atividade
  def color
    case activity_type
    when 'created' then 'blue'
    when 'edited' then 'yellow'
    when 'sent' then 'indigo'
    when 'viewed' then 'gray'
    when 'signed' then 'green'
    when 'refused' then 'red'
    when 'expired' then 'orange'
    when 'cancelled' then 'red'
    when 'reminder_sent' then 'purple'
    else 'gray'
    end
  end

  # Autor da atividade (usuário ou signatário)
  def author_name
    if user.present?
      user.display_name || user.name || user.email
    elsif contract_signer.present?
      contract_signer.name
    else
      'Sistema'
    end
  end

  # Label do tipo em português
  def type_label
    case activity_type
    when 'created' then 'Criado'
    when 'edited' then 'Editado'
    when 'sent' then 'Enviado'
    when 'viewed' then 'Visualizado'
    when 'signed' then 'Assinado'
    when 'refused' then 'Recusado'
    when 'expired' then 'Expirado'
    when 'cancelled' then 'Cancelado'
    when 'reminder_sent' then 'Lembrete enviado'
    else activity_type
    end
  end
end
