# frozen_string_literal: true

json.data do
  json.pending do
    json.array! @tasks_by_status[:pending], partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
  end

  json.in_progress do
    json.array! @tasks_by_status[:in_progress], partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
  end

  json.completed do
    json.array! @tasks_by_status[:completed], partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
  end

  json.cancelled do
    json.array! @tasks_by_status[:cancelled], partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
  end
end

json.meta do
  json.pending_count @tasks_by_status[:pending].size
  json.in_progress_count @tasks_by_status[:in_progress].size
  json.completed_count @tasks_by_status[:completed].size
  json.cancelled_count @tasks_by_status[:cancelled].size
end
