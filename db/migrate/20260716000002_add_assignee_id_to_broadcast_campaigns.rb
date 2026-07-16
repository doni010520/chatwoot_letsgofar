# frozen_string_literal: true

class AddAssigneeIdToBroadcastCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :broadcast_campaigns, :assignee_id, :bigint
  end
end
