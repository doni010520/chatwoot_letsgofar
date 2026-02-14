class AddCrmFieldsToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :deal_value, :decimal, precision: 15, scale: 2, default: nil
    add_column :conversations, :closed_at, :datetime, default: nil
    add_column :conversations, :closed_won, :boolean, default: nil
    add_column :conversations, :closed_reason, :string, default: nil
  end
end
