# frozen_string_literal: true

class CreateAgentTaskItems < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_task_items do |t|
      t.references :agent_task, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.boolean :completed, default: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :agent_task_items, [:agent_task_id, :position]
    add_index :agent_task_items, [:agent_task_id, :completed]
  end
end
