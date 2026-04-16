# frozen_string_literal: true

namespace :lead_tracking do
  desc 'Seed CRM custom fields for lead tracking on all Kanban pipelines'
  task seed_fields: :environment do
    fields_config = [
      {
        name: 'Origem do Lead',
        field_key: 'lead_source',
        field_type: 'select',
        select_options: [
          'LinkedIn (Prospecção Ativa)',
          'Instagram (Prospecção Ativa)',
          'Jetsales/WhatsApp (Prospecção Ativa)',
          'Tráfego Pago',
          'Lançamento/Webinário/Evento',
          'Passivo (Inbound)',
          'Indicação',
          'Follow Up Mês Anterior'
        ],
        required: false,
        show_on_card: true,
        position: 1
      },
      {
        name: 'Tipo de Lead',
        field_key: 'lead_type',
        field_type: 'select',
        select_options: [
          'Novo',
          'Follow Up',
          'Renovação',
          'Reativação'
        ],
        required: false,
        show_on_card: true,
        position: 2
      },
      {
        name: 'Call Realizada',
        field_key: 'call_done',
        field_type: 'checkbox',
        select_options: nil,
        required: false,
        show_on_card: true,
        position: 3
      },
      {
        name: 'Data da Call',
        field_key: 'call_date',
        field_type: 'date',
        select_options: nil,
        required: false,
        show_on_card: false,
        position: 4
      },
      {
        name: 'Respondeu',
        field_key: 'responded',
        field_type: 'checkbox',
        select_options: nil,
        required: false,
        show_on_card: true,
        position: 5
      },
      {
        name: 'Tipo de Contrato',
        field_key: 'contract_type',
        field_type: 'select',
        select_options: [
          'Nova Venda',
          'Renovação'
        ],
        required: false,
        show_on_card: false,
        position: 6
      },
      {
        name: 'Faturamento Real (mês)',
        field_key: 'monthly_revenue',
        field_type: 'currency',
        select_options: nil,
        required: false,
        show_on_card: true,
        position: 7
      }
    ]

    pipelines = KanbanPipeline.all

    if pipelines.empty?
      puts '[lead_tracking:seed_fields] No KanbanPipeline found. Skipping.'
      next
    end

    pipelines.find_each do |pipeline|
      puts "Processing pipeline: #{pipeline.name} (id=#{pipeline.id}, account_id=#{pipeline.account_id})"

      fields_config.each do |config|
        field = KanbanCustomField.find_or_initialize_by(
          kanban_pipeline_id: pipeline.id,
          field_key: config[:field_key]
        )

        field.assign_attributes(
          account_id: pipeline.account_id,
          name: config[:name],
          field_type: config[:field_type],
          required: config[:required],
          show_on_card: config[:show_on_card],
          position: config[:position]
        )

        field.select_options = config[:select_options] if config[:select_options].present?

        if field.new_record?
          field.save!
          puts "  [CREATED] #{config[:field_key]} - #{config[:name]}"
        elsif field.changed?
          field.save!
          puts "  [UPDATED] #{config[:field_key]} - #{config[:name]}"
        else
          puts "  [EXISTS]  #{config[:field_key]} - #{config[:name]}"
        end
      end
    end

    puts 'Done seeding lead tracking custom fields.'
  end
end
