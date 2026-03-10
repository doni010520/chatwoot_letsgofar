# frozen_string_literal: true

# == Schema Information
#
# Table name: contract_templates
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  created_by_id   :bigint
#  name            :string           not null
#  description     :text
#  content_html    :text             not null
#  active          :boolean          default(TRUE)
#  variable_fields :jsonb
#  created_at      :datetime
#  updated_at      :datetime
#
class ContractTemplate < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  # Validações
  validates :name, presence: true
  validates :content_html, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Campos variáveis padrão para o contrato Let's Go Far
  DEFAULT_VARIABLE_FIELDS = [
    # Dados do Contratante
    { key: 'contractor_name', label: 'Nome do Contratante', type: 'text', required: true },
    { key: 'contractor_cpf', label: 'CPF', type: 'cpf', required: true },
    { key: 'contractor_rg', label: 'RG', type: 'text', required: false },
    { key: 'contractor_address', label: 'Endereço', type: 'text', required: true },
    { key: 'contractor_neighborhood', label: 'Bairro', type: 'text', required: true },
    { key: 'contractor_city', label: 'Cidade', type: 'text', required: true },
    { key: 'contractor_cep', label: 'CEP', type: 'cep', required: true },
    { key: 'contractor_state', label: 'Estado', type: 'select', required: true },
    { key: 'contractor_email', label: 'E-mail', type: 'email', required: true },
    { key: 'contractor_phone', label: 'Telefone', type: 'phone', required: true },
    { key: 'contractor_birth_date', label: 'Data de Nascimento', type: 'date', required: false },
    
    # Dados do Plano (Anexo I)
    { key: 'plan_name', label: 'Nome do Plano', type: 'text', required: true },
    { key: 'plan_duration', label: 'Duração do Plano', type: 'text', required: true },
    { key: 'sessions_call_estrategica', label: 'Sessões Call Estratégica', type: 'number', required: false },
    { key: 'sessions_individual', label: 'Sessões Individuais', type: 'number', required: false },
    { key: 'sessions_group_consultive', label: 'Sessões Consultivas em Grupo', type: 'number', required: false },
    { key: 'sessions_group_meetings', label: 'Encontros em Grupo', type: 'number', required: false },
    { key: 'plan_value', label: 'Valor Total', type: 'currency', required: true },
    { key: 'installments_count', label: 'Número de Parcelas', type: 'number', required: true },
    { key: 'first_installment_value', label: 'Valor da 1ª Parcela', type: 'currency', required: false },
    { key: 'installment_due_day', label: 'Dia de Vencimento', type: 'number', required: true }
  ].freeze

  # Aplicar variáveis ao template
  def apply_variables(variables = {})
    result = content_html.dup

    variables.each do |key, value|
      placeholder = "{{#{key}}}"
      result.gsub!(placeholder, value.to_s)
    end

    result
  end

  # Extrair placeholders do template
  def extract_placeholders
    content_html.scan(/\{\{(\w+)\}\}/).flatten.uniq
  end

  # Verificar se todos os campos obrigatórios estão preenchidos
  def validate_variables(variables = {})
    missing = []
    
    variable_fields_list = variable_fields.presence || DEFAULT_VARIABLE_FIELDS
    
    variable_fields_list.each do |field|
      field_data = field.is_a?(Hash) ? field : field.to_h
      if field_data[:required] || field_data['required']
        key = field_data[:key] || field_data['key']
        missing << key if variables[key].blank? && variables[key.to_sym].blank?
      end
    end

    missing
  end

  # Duplicar template
  def duplicate!(user = nil)
    new_template = dup
    new_template.name = "#{name} (Cópia)"
    new_template.c
