class CreateKanbanActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_activities do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :activity_type, null: false
      t.string :title
      t.text :description
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :kanban_activities, [:conversation_id, :created_at]
    add_index :kanban_activities, :activity_type
  end
end
