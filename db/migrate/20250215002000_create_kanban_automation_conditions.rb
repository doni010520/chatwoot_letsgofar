# db/migrate/20250215002000_create_kanban_automation_conditions.rb
class CreateKanbanAutomationConditions < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_automation_conditions do |t|
      t.references :kanban_automation, null: false, foreign_key: { on_delete: :cascade }
      t.string :field, null: false
      t.string :operator, null: false
      t.string :value
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :kanban_automation_conditions, [:kanban_automation_id, :position], name: 'idx_automation_conditions_position'
  end
end
