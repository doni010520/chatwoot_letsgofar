# frozen_string_literal: true

class CreateAgentTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_tasks do |t|
      # Relacionamentos obrigatórios
      t.references :account, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }

      # Vínculos opcionais
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :kanban_pipeline, foreign_key: true

      # Campos da tarefa
      t.string :title, null: false
      t.text :description
      t.string :priority, default: 'medium', null: false
      t.string :status, default: 'pending', null: false

      # Datas
      t.date :due_date
      t.time :due_time
      t.datetime :reminder_at
      t.datetime :completed_at
      t.datetime :started_at

      # Controle de notificações
      t.boolean :reminder_sent, default: false
      t.boolean :overdue_notified, default: false

      # Metadados
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # Índices para performance
    add_index :agent_tasks, [:account_id, :status]
    add_index :agent_tasks, [:account_id, :assigned_to_id]
    add_index :agent_tasks, [:account_id, :created_by_id]
    add_index :agent_tasks, [:account_id, :due_date]
    add_index :agent_tasks, [:account_id, :priority]
    add_index :agent_tasks, :contact_id
    add_index :agent_tasks, :conversation_id
    add_index :agent_tasks, :kanban_pipeline_id
    add_index :agent_tasks, :reminder_at
  end
end
