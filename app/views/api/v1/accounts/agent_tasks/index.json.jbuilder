# frozen_string_literal: true

json.data do
  json.array! @agent_tasks, partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
end

json.meta do
  json.current_page @agent_tasks.current_page
  json.per_page @agent_tasks.limit_value
  json.total_count @agent_tasks.total_count
  json.total_pages @agent_tasks.total_pages
end
