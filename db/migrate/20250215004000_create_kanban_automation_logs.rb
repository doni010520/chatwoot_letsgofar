# db/migrate/20250215004000_create_kanban_automation_logs.rb
class CreateKanbanAutomationLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_automation_logs do |t|
      t.references :kanban_automation, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: true, foreign_key: true
      t.jsonb :trigger_data, default: {}
      t.jsonb :actions_executed, default: []
      t.string :status, default: 'pending'
      t.text :error_message
      t.datetime :executed_at

      t.timestamps
    end

    add_index :kanban_automation_logs, :status
    add_index :kanban_automation_logs, :executed_at
    add_index :kanban_automation_logs, [:kanban_automation_id, :status], name: 'idx_automation_logs_status'
  end
end
