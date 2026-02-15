# db/migrate/20250215003000_create_kanban_automation_actions.rb
class CreateKanbanAutomationActions < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_automation_actions do |t|
      t.references :kanban_automation, null: false, foreign_key: { on_delete: :cascade }
      t.string :action_type, null: false
      t.jsonb :action_config, default: {}
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :kanban_automation_actions, [:kanban_automation_id, :position], name: 'idx_automation_actions_position'
  end
end
