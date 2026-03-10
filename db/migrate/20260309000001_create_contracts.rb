# frozen_string_literal: true

class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    # Tabela principal de contratos
    create_table :contracts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, foreign_key: true # Opcional - vincula ao contato do Chatwoot
      t.references :created_by, foreign_key: { to_table: :users }

      # Identificação
      t.string :title, null: false
      t.string :contract_number, null: false # Número único do contrato
      
      # Conteúdo
      t.text :content_html # Conteúdo HTML editável do contrato
      t.string :document_hash # SHA-256 do documento final
      
      # Status: draft, pending, partially_signed, signed, refused, expired, cancelled
      t.string :status, default: 'draft', null: false
      
      # Datas
      t.datetime :sent_at
      t.datetime :signed_at
      t.datetime :expires_at
      t.datetime :cancelled_at
      
      # Dados do contratante (campos do formulário)
      t.string :contractor_name
      t.string :contractor_cpf
      t.string :contractor_rg
      t.string :contractor_address
      t.string :contractor_neighborhood
      t.string :contractor_city
      t.string :contractor_cep
      t.string :contractor_state
      t.string :contractor_email
      t.string :contractor_phone
      t.date :contractor_birth_date
      
      # Dados do plano (Anexo I)
      t.string :plan_name
      t.string :plan_duration
      t.integer :sessions_call_estrategica, default: 0
      t.integer :sessions_individual, default: 0
      t.integer :sessions_group_consultive, default: 0
      t.integer :sessions_group_meetings, default: 0
      t.decimal :plan_value, precision: 10, scale: 2
      t.integer :installments_count
      t.decimal :first_installment_value, precision: 10, scale: 2
      t.integer :installment_due_day
      
      # Metadados
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :contracts, :contract_number, unique: true
    add_index :contracts, :status
    add_index :contracts, [:account_id, :status]
    add_index :contracts, [:account_id, :created_at]

    # Tabela de signatários
    create_table :contract_signers do |t|
      t.references :contract, null: false, foreign_key: true
      
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, default: 'contractor' # contractor, contracted, witness
      t.string :sign_token, null: false # Token único para o link de assinatura
      
      # Status: pending, viewed, signed, refused
      t.string :status, default: 'pending', null: false
      
      # Datas
      t.datetime :viewed_at
      t.datetime :signed_at
      t.datetime :refused_at
      
      # Motivo da recusa (se aplicável)
      t.text :refusal_reason
      
      t.timestamps
    end

    add_index :contract_signers, :sign_token, unique: true
    add_index :contract_signers, [:contract_id, :status]

    # Tabela de evidências de assinatura (validade jurídica)
    create_table :contract_signatures do |t|
      t.references :contract_signer, null: false, foreign_key: true
      
      # Evidências capturadas
      t.string :ip_address
      t.text :user_agent
      t.string :geolocation # lat,lng
      t.datetime :signed_at, null: false
      t.string :signature_hash # Hash da assinatura (SHA-256)
      
      # Dados adicionais
      t.string :browser_fingerprint
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    # Tabela de templates de contrato
    create_table :contract_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      
      t.string :name, null: false
      t.text :description
      t.text :content_html, null: false # Template HTML com placeholders
      t.boolean :active, default: true
      
      # Campos variáveis do template (para o formulário)
      t.jsonb :variable_fields, default: []
      
      t.timestamps
    end

    add_index :contract_templates, [:account_id, :active]

    # Tabela de histórico/atividades do contrato
    create_table :contract_activities do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :user, foreign_key: true # Null se for ação do signatário
      t.references :contract_signer, foreign_key: true # Se for ação do signatário
      
      # created, sent, viewed, signed, refused, expired, cancelled, edited, reminder_sent
      t.string :activity_type, null: false
      t.text :description
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :contract_activities, [:contract_id, :created_at]
  end
end
