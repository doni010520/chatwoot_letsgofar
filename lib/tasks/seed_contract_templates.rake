# frozen_string_literal: true

namespace :contracts do
  desc 'Seed default contract template for all accounts'
  task seed_templates: :environment do
    puts 'Seeding contract templates...'

    # Use the same default HTML from the controller
    controller = Api::V1::Accounts::ContractTemplatesController.new
    default_html = controller.send(:default_contract_html)

    variable_fields = [
      { key: 'contractor_name', label: 'Nome do Aluno', type: 'text', required: true },
      { key: 'contractor_cpf', label: 'CPF', type: 'cpf', required: true },
      { key: 'contractor_rg', label: 'RG', type: 'text', required: false },
      { key: 'contractor_address', label: 'Endereço', type: 'text', required: true },
      { key: 'contractor_neighborhood', label: 'Bairro', type: 'text', required: true },
      { key: 'contractor_city', label: 'Município', type: 'text', required: true },
      { key: 'contractor_cep', label: 'CEP', type: 'cep', required: true },
      { key: 'contractor_state', label: 'Estado', type: 'state', required: true },
      { key: 'contractor_email', label: 'E-mail', type: 'email', required: true },
      { key: 'contractor_phone', label: 'Telefone', type: 'phone', required: true },
      { key: 'contractor_birth_date', label: 'Data de Nascimento', type: 'date', required: true },
      { key: 'plan_name', label: 'Nome do Plano', type: 'text', required: true, default: 'ASSESSORIA' },
      { key: 'plan_duration', label: 'Duração Aproximada', type: 'text', required: true },
      { key: 'plan_start_date', label: 'Início do Plano', type: 'date', required: true },
      { key: 'plan_end_date', label: 'Término do Plano', type: 'date', required: false },
      { key: 'sessions_call_estrategica', label: 'Sessões Call Estratégica', type: 'number', required: true },
      { key: 'sessions_individual', label: 'Sessões Consultivas Individuais', type: 'number', required: true },
      { key: 'sessions_group_consultive', label: 'Sessões Consultivas em Grupo', type: 'number', required: true },
      { key: 'sessions_group_meetings', label: 'Encontros em Grupo', type: 'number', required: true },
      { key: 'plan_value', label: 'Valor Total do Plano', type: 'currency', required: true },
      { key: 'installments_count', label: 'Número de Parcelas', type: 'number', required: true },
      { key: 'first_installment_value', label: 'Valor 1ª Parcela (Matrícula)', type: 'currency', required: true },
      { key: 'installment_due_day', label: 'Dia de Vencimento das Parcelas', type: 'number', required: true },
      { key: 'contract_date', label: 'Data do Contrato', type: 'date', required: true }
    ]

    Account.find_each do |account|
      next if account.contract_templates.exists?(name: 'Contrato Padrão - Let\'s Go Far')

      template = account.contract_templates.new(
        name: 'Contrato Padrão - Let\'s Go Far',
        description: 'Contrato de Assessoria Consultiva de Inglês - Let\'s Go Far (Completo com 12 cláusulas)',
        content_html: default_html,
        active: true,
        variable_fields: variable_fields,
        created_by: account.users.where('account_users.role = ?', 'administrator').first
      )

      if template.save
        puts "  ✅ Template criado para conta: #{account.name} (ID: #{account.id})"
      else
        puts "  ❌ Erro na conta #{account.id}: #{template.errors.full_messages.join(', ')}"
      end
    end

    puts 'Done!'
  end
end
