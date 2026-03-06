# frozen_string_literal: true

json.id agent_task.id
json.title agent_task.title
json.description agent_task.description
json.status agent_task.status
json.priority agent_task.priority

json.due_date agent_task.due_date
json.due_time agent_task.due_time&.strftime('%H:%M')
json.reminder_at agent_task.reminder_at

json.completed_at agent_task.completed_at
json.started_at agent_task.started_at
json.created_at agent_task.created_at
json.updated_at agent_task.updated_at

json.overdue agent_task.overdue?
json.due_today agent_task.due_today?

json.progress_percentage agent_task.progress_percentage
json.items_summary agent_task.items_summary

json.created_by do
  if agent_task.created_by
    json.id agent_task.created_by.id
    json.name agent_task.created_by.name
    json.avatar_url agent_task.created_by.avatar_url
  end
end

json.assigned_to do
  if agent_task.assigned_to
    json.id agent_task.assigned_to.id
    json.name agent_task.assigned_to.name
    json.avatar_url agent_task.assigned_to.avatar_url
  end
end

json.contact do
  if agent_task.contact
    json.id agent_task.contact.id
    json.name agent_task.contact.name
    json.email agent_task.contact.email
    json.phone_number agent_task.contact.phone_number
    json.avatar_url agent_task.contact.avatar_url
  end
end

json.conversation do
  if agent_task.conversation
    json.id agent_task.conversation.id
    json.display_id agent_task.conversation.display_id
    json.status agent_task.conversation.status
  end
end

json.kanban_pipeline do
  if agent_task.kanban_pipeline
    json.id agent_task.kanban_pipeline.id
    json.name agent_task.kanban_pipeline.name
  end
end

json.labels agent_task.labels do |label|
  json.id label.id
  json.title label.title
  json.color label.color
end

json.files agent_task.files.map { |file|
  {
    id: file.id,
    filename: file.filename.to_s,
    content_type: file.content_type,
    byte_size: file.byte_size,
    url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
  }
}

json.files_count agent_task.files.count
json.items_count agent_task.items.count
json.items_completed_count agent_task.items.completed.count
json.comments_count agent_task.comments.count
