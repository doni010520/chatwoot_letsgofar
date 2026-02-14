# frozen_string_literal: true

class CreateKanbanPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_pipelines do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :pipeline_type, default: 0, null: false
      t.boolean :is_default, default: false

      t.timestamps
    end

    add_index :kanban_pipelines, %i[account_id name], unique: true
    add_index :kanban_pipelines, %i[account_id is_default]
  end
end