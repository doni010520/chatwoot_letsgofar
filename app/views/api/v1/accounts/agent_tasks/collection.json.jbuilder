# frozen_string_literal: true

json.array! @agent_tasks, partial: 'api/v1/accounts/agent_tasks/agent_task', as: :agent_task
