class CreateKanbanCustomFieldValues < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_custom_field_values do |t|
      t.references :kanban_custom_field, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.text :value
      t.timestamps
    end

    add_index :kanban_custom_field_values, [:kanban_custom_field_id, :conversation_id], unique: true, name: 'idx_custom_field_values_unique'
  end
end
