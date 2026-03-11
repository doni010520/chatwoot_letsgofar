class AddRecurrenceToAgentTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :agent_tasks, :recurrence_type, :string, default: 'none'
    add_column :agent_tasks, :recurrence_config, :jsonb, default: {}
    add_index :agent_tasks, :recurrence_type
  end
end
