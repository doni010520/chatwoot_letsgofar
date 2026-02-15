class CreateKanbanTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_tasks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.datetime :due_at
      t.datetime :completed_at
      t.string :priority, default: 'medium'
      t.string :status, default: 'pending'
      t.timestamps
    end

    add_index :kanban_tasks, [:conversation_id, :status]
    add_index :kanban_tasks, [:assigned_to_id, :status]
    add_index :kanban_tasks, :due_at
  end
end
