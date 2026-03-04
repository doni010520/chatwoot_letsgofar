# frozen_string_literal: true

class CreateAgentTaskComments < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_task_comments do |t|
      t.references :agent_task, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :agent_task_comments, [:agent_task_id, :created_at]
  end
end
