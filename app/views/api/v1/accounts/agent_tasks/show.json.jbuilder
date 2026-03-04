# frozen_string_literal: true

json.partial! 'api/v1/accounts/agent_tasks/agent_task', agent_task: @agent_task

json.items @agent_task.items.ordered do |item|
  json.id item.id
  json.title item.title
  json.completed item.completed
  json.position item.position
  json.created_at item.created_at
end

json.comments @agent_task.comments.includes(:user).ordered do |comment|
  json.id comment.id
  json.content comment.content
  json.created_at comment.created_at
  json.user do
    json.id comment.user.id
    json.name comment.user.name
    json.avatar_url comment.user.avatar_url
  end
end
