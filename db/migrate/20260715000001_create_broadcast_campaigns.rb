# frozen_string_literal: true

class CreateBroadcastCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcast_campaigns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :user, foreign_key: true # created_by
      t.string :title, null: false
      t.text :message_template, null: false
      t.string :status, null: false, default: 'draft'
      t.integer :min_interval, null: false, default: 300 # segundos
      t.integer :max_interval, null: false, default: 360 # segundos
      t.integer :send_window_start, null: false, default: 9  # hora 0-23
      t.integer :send_window_end, null: false, default: 18   # hora 0-23
      t.integer :daily_cap, null: false, default: 50
      t.integer :sent_today, null: false, default: 0
      t.date :sent_today_on
      t.integer :total_count, null: false, default: 0
      t.integer :sent_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.datetime :next_run_at
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :broadcast_campaigns, [:account_id, :status]

    create_table :broadcast_recipients do |t|
      t.references :broadcast_campaign, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :phone, null: false
      t.string :name
      t.jsonb :merge_fields, null: false, default: {}
      t.string :status, null: false, default: 'pending'
      t.text :personalized_message
      t.bigint :conversation_id
      t.text :error
      t.integer :position, null: false, default: 0
      t.datetime :sent_at
      t.timestamps
    end
    add_index :broadcast_recipients, [:broadcast_campaign_id, :status]
    add_index :broadcast_recipients, [:broadcast_campaign_id, :position]
  end
end
