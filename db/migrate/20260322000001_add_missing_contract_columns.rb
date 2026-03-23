# frozen_string_literal: true

class AddMissingContractColumns < ActiveRecord::Migration[7.0]
  def change
    # Colunas faltantes na tabela contracts
    add_column :contracts, :variables, :jsonb, default: {}
    add_column :contracts, :plan_start_date, :date
    add_column :contracts, :plan_end_date, :date
    add_reference :contracts, :contract_template, foreign_key: true

    # Colunas faltantes na tabela contract_signers
    add_column :contract_signers, :auto_sign, :boolean, default: false, null: false
    add_column :contract_signers, :cpf, :string
    add_column :contract_signers, :sign_order, :integer, default: 1

    # Colunas faltantes na tabela contract_signatures
    add_column :contract_signatures, :confirmation_name, :string
    add_column :contract_signatures, :confirmation_cpf, :string

    # Coluna faltante na tabela contract_activities
    add_column :contract_activities, :ip_address, :string

    # Índices para consultas de vencimento
    add_index :contracts, :plan_end_date
    add_index :contracts, [:status, :plan_end_date]
  end
end
