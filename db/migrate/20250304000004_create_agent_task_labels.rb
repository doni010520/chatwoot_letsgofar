# frozen_string_literal: true

class CreateAgentTaskLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_task_labels do |t|
      t.references :agent_task, null: false, foreign_key: { on_delete: :cascade }
      t.references :label, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :agent_task_labels, [:agent_task_id, :label_id], unique: true
  end
end
