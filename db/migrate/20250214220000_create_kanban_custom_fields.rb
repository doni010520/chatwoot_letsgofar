class CreateKanbanCustomFields < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_custom_fields do |t|
      t.references :account, null: false, foreign_key: true
      t.references :kanban_pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_key, null: false
      t.string :field_type, null: false, default: 'text'
      t.text :description
      t.jsonb :options, default: {}
      t.boolean :required, default: false
      t.boolean :show_on_card, default: false
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :kanban_custom_fields, [:kanban_pipeline_id, :field_key], unique: true
    add_index :kanban_custom_fields, [:kanban_pipeline_id, :position]
  end
end
