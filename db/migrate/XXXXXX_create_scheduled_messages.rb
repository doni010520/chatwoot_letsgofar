class CreateScheduledMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      t.text :content, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      
      t.timestamps
      
      t.index [:account_id, :status]
      t.index [:scheduled_at, :status]
    end
  end
end
