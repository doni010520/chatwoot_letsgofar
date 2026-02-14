# frozen_string_literal: true

class CreateKanbanStages < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_stages do |t|
      t.references :kanban_pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :color, default: '#6366F1'

      t.timestamps
    end

    add_index :kanban_stages, %i[kanban_pipeline_id position]
    add_index :kanban_stages, %i[kanban_pipeline_id name], unique: true
  end
end