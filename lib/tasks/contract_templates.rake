# frozen_string_literal: true

namespace :contracts do
  desc 'Seed contract templates from external app (Assessoria + Aulas em Grupo)'
  task seed_templates: :environment do
    puts 'Seeding contract templates...'

    account = Account.first
    user = User.first

    unless account && user
      puts 'No account or user found. Create them first.'
      next
    end

    # Template 1: Assessoria Consultiva
    assessoria_file = Rails.root.join('db', 'seeds_contract_template_assessoria.rb')
    if File.exist?(assessoria_file)
      # Read the file and extract the template_content heredoc
      content = File.read(assessoria_file)
      # Extract HTML between <<~HTML and the closing HTML
      html_match = content.match(/template_content\s*=\s*<<~HTML\n(.*?)^HTML/m)
      if html_match
        template = ContractTemplate.find_or_initialize_by(
          account: account,
          name: 'Contrato Padrão - Assessoria Consultiva'
        )
        template.content_html = html_match[1]
        template.description = 'Contrato de Assessoria Consultiva de Inglês - Let\'s Go Far (Completo)'
        template.created_by = user
        template.active = true
        template.save!
        puts "  ✅ '#{template.name}' saved (id: #{template.id})"
      else
        puts '  ❌ Could not parse assessoria template HTML'
      end
    else
      puts "  ❌ File not found: #{assessoria_file}"
    end

    # Template 2: Aulas em Grupo
    aulas_file = Rails.root.join('db', 'seeds_contract_template_aulas_grupo.rb')
    if File.exist?(aulas_file)
      content = File.read(aulas_file)
      html_match = content.match(/template_aulas_grupo\s*=\s*<<~HTML\n(.*?)^HTML/m)
      if html_match
        template = ContractTemplate.find_or_initialize_by(
          account: account,
          name: 'Contrato de Aulas em Grupo - Executive Class'
        )
        template.content_html = html_match[1]
        template.description = 'Contrato de Aulas em Grupo (Executive Class) - Let\'s Go Far'
        template.created_by = user
        template.active = true
        template.save!
        puts "  ✅ '#{template.name}' saved (id: #{template.id})"
      else
        puts '  ❌ Could not parse aulas em grupo template HTML'
      end
    else
      puts "  ❌ File not found: #{aulas_file}"
    end

    puts "\nDone! #{ContractTemplate.where(account: account).count} templates available."
  end
end
