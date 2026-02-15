# app/jobs/kanban_overdue_tasks_job.rb
class KanbanOverdueTasksJob < ApplicationJob
  queue_as :scheduled_jobs

  # Run hourly to check for overdue tasks
  def perform
    Rails.logger.info '[KanbanOverdueTasksJob] Starting overdue tasks check...'

    # Find tasks that just became overdue (within last hour to avoid duplicates)
    newly_overdue_tasks = KanbanTask
                          .where(status: %w[pending in_progress])
                          .where.not(due_at: nil)
                          .where('due_at < ? AND due_at > ?', Time.current, 1.hour.ago)
                          .includes(conversation: :kanban_stage)

    Rails.logger.info "[KanbanOverdueTasksJob] Found #{newly_overdue_tasks.count} newly overdue tasks"

    newly_overdue_tasks.find_each do |task|
      next unless task.conversation&.kanban_stage_id.present?

      KanbanAutomationService.on_task_overdue(task.conversation, task)
    end

    Rails.logger.info '[KanbanOverdueTasksJob] Completed'
  end
end
