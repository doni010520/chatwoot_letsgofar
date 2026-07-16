# frozen_string_literal: true

class AddContactIdToBroadcastRecipients < ActiveRecord::Migration[7.1]
  def change
    add_column :broadcast_recipients, :contact_id, :bigint
    add_index :broadcast_recipients, :contact_id
  end
end
