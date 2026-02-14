# frozen_string_literal: true

class AddKanbanStageToConversationsAndContacts < ActiveRecord::Migration[7.0]
  def change
    add_reference :conversations, :kanban_stage, foreign_key: { to_table: :kanban_stages }, null: true
    add_reference :contacts, :kanban_stage, foreign_key: { to_table: :kanban_stages }, null: true
  end
end