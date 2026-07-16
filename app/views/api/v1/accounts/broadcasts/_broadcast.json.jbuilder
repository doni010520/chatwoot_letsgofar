# frozen_string_literal: true

json.id broadcast.id
json.title broadcast.title
json.message_template broadcast.message_template
json.status broadcast.status
json.inbox_id broadcast.inbox_id
json.assignee_id broadcast.assignee_id
json.min_interval broadcast.min_interval
json.max_interval broadcast.max_interval
json.send_window_start broadcast.send_window_start
json.send_window_end broadcast.send_window_end
json.daily_cap broadcast.daily_cap
json.total_count broadcast.total_count
json.sent_count broadcast.sent_count
json.failed_count broadcast.failed_count
json.pending_count broadcast.broadcast_recipients.pending.count
json.next_run_at broadcast.next_run_at
json.started_at broadcast.started_at
json.completed_at broadcast.completed_at
json.created_at broadcast.created_at
json.updated_at broadcast.updated_at
