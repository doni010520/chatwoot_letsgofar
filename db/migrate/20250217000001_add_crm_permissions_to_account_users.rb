# frozen_string_literal: true

class AddCrmPermissionsToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    # Adiciona coluna para permissões específicas do CRM
    # Cada permissão é um bit flag para performance
    add_column :account_users, :crm_permissions, :integer, default: 0, null: false

    # Adiciona coluna para restringir visibilidade do CRM
    # all: vê todos os cards
    # team: vê cards do seu time
    # own: vê apenas cards atribuídos a ele
    add_column :account_users, :crm_visibility, :integer, default: 0, null: false

    # Índice para queries de permissão
    add_index :account_users, :crm_permissions
  end
end
