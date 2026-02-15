# frozen_string_literal: true

require 'csv'

class Api::V1::Accounts::Kanban::ImportsController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline

  def create
    file = params[:file]
    stage_id = params[:stage_id]
    
    unless file.present?
      return render json: { error: 'Arquivo não enviado' }, status: :unprocessable_entity
    end

    unless stage_id.present?
      return render json: { error: 'Estágio não selecionado' }, status: :unprocessable_entity
    end

    stage = @pipeline.kanban_stages.find(stage_id)
    results = { success: 0, errors: [] }

    begin
      # Detectar encoding e ler CSV
      content = file.read.force_encoding('UTF-8')
      content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      
      csv = CSV.parse(content, headers: true, col_sep: detect_separator(content))

      csv.each_with_index do |row, index|
        begin
          # Buscar ou criar contato
          contact = find_or_create_contact(row)
          
          # Buscar inbox padrão (primeiro disponível)
          inbox = Current.account.inboxes.first
          
          unless inbox
            results[:errors] << { row: index + 2, error: 'Nenhuma inbox disponível' }
            next
          end

          # Criar conversa
          conversation = Current.account.conversations.create!(
            contact: contact,
            inbox: inbox,
            kanban_stage_id: stage.id,
            deal_value: parse_currency(row['valor'] || row['Valor'] || row['deal_value']),
            status: :open
          )

          # Preencher campos personalizados
          fill_custom_fields(conversation, row)

          results[:success] += 1
        rescue StandardError => e
          results[:errors] << { row: index + 2, error: e.message }
        end
      end

      render json: {
        message: "Importação concluída: #{results[:success]} leads importados",
        success_count: results[:success],
        error_count: results[:errors].size,
        errors: results[:errors].first(10)
      }
    rescue StandardError => e
      render json: { error: "Erro ao processar arquivo: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def template
    custom_fields = @pipeline.kanban_custom_fields.ordered
    
    csv_data = CSV.generate(headers: true, col_sep: ';') do |csv|
      headers = ['nome', 'email', 'telefone', 'valor']
      custom_fields.each { |cf| headers << cf.field_key }
      csv << headers
      
      # Linha de exemplo
      example = ['João Silva', 'joao@email.com', '11999999999', '15000']
      custom_fields.each do |cf|
        case cf.field_type
        when 'number', 'currency'
          example << '100'
        when 'checkbox'
          example << 'true'
        when 'date'
          example << Date.current.to_s
        when 'select', 'multiselect'
          example << cf.select_options&.first
        else
          example << 'Exemplo'
        end
      end
      csv << example
    end
    
    send_data csv_data,
              filename: "template_importacao_#{@pipeline.name.parameterize}.csv",
              type: 'text/csv; charset=utf-8'
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def detect_separator(content)
    first_line = content.lines.first.to_s
    return ';' if first_line.count(';') > first_line.count(',')
    ','
  end

  def find_or_create_contact(row)
    name = row['nome'] || row['Nome'] || row['name'] || 'Sem nome'
    email = row['email'] || row['Email'] || row['e-mail']
    phone = row['telefone'] || row['Telefone'] || row['phone'] || row['celular'] || row['Celular']

    # Limpar telefone
    phone = phone.to_s.gsub(/\D/, '') if phone.present?

    # Buscar contato existente por email ou telefone
    contact = nil
    contact = Current.account.contacts.find_by(email: email) if email.present?
    contact ||= Current.account.contacts.find_by(phone_number: phone) if phone.present?

    # Criar se não existir
    contact ||= Current.account.contacts.create!(
      name: name,
      email: email,
      phone_number: phone
    )

    contact
  end

  def parse_currency(value)
    return nil if value.blank?
    
    # Remover R$, espaços e converter vírgula para ponto
    cleaned = value.to_s
                   .gsub(/[R$\s]/, '')
                   .gsub('.', '')
                   .gsub(',', '.')
    
    cleaned.to_f
  end

  def fill_custom_fields(conversation, row)
    @pipeline.kanban_custom_fields.each do |field|
      value = row[field.field_key] || row[field.name]
      next if value.blank?

      conversation.kanban_custom_field_values.create!(
        kanban_custom_field: field,
        value: value.to_s
      )
    end
  end
end
