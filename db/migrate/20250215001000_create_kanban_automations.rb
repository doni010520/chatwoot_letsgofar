# db/migrate/20250215001000_create_kanban_automations.rb
class CreateKanbanAutomations < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_automations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :kanban_pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :trigger_type, null: false
      t.jsonb :trigger_config, default: {}
      t.boolean :is_active, default: true
      t.integer :execution_order, default: 0
      t.integer :executions_count, default: 0
      t.datetime :last_executed_at

      t.timestamps
    end

    add_index :kanban_automations, [:account_id, :is_active]
    add_index :kanban_automations, [:kanban_pipeline_id, :trigger_type]
    add_index :kanban_automations, :trigger_type
  end
end
