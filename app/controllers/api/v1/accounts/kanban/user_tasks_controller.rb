# frozen_string_literal: true

class Api::V1::Accounts::Kanban::UserTasksController < Api::V1::Accounts::Kanban::BaseController
  def summary
    tasks = Current.account.kanban_tasks
                   .where(status: ['pending', 'in_progress'])
                   .where(assigned_to_id: [Current.user.id, nil])

    today_start = Time.current.beginning_of_day
    today_end = Time.current.end_of_day
    tomorrow_end = (Time.current + 1.day).end_of_day

    overdue_count = tasks.where('due_at < ?', today_start).count
    due_today_count = tasks.where(due_at: today_start..today_end).count
    due_tomorrow_count = tasks.where(due_at: today_end..tomorrow_end).count
    total_pending = tasks.count

    render json: {
      overdue: overdue_count,
      due_today: due_today_count,
      due_tomorrow: due_tomorrow_count,
      total_pending: total_pending,
      urgent_count: overdue_count + due_today_count
    }
  end

  def index
    tasks = Current.account.kanban_tasks
                   .includes(:conversation, :user, conversation: :contact)
                   .where(status: ['pending', 'in_progress'])
                   .where(assigned_to_id: [Current.user.id, nil])

    # Filtro por tipo
    case params[:filter]
    when 'overdue'
      tasks = tasks.where('due_at < ?', Time.current.beginning_of_day)
    when 'today'
      tasks = tasks.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day)
    when 'tomorrow'
      tasks = tasks.where(due_at: Time.current.end_of_day..(Time.current + 1.day).end_of_day)
    when 'week'
      tasks = tasks.where(due_at: Time.current.beginning_of_day..(Time.current + 7.days).end_of_day)
    end

    tasks = tasks.order(due_at: :asc).limit(50)

    render json: tasks.map { |t| task_with_conversation_json(t) }
  end

  private

  def task_with_conversation_json(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      due_at: task.due_at,
      priority: task.priority,
      status: task.status,
      overdue: task.overdue?,
      conversation: task.conversation ? {
        id: task.conversation.id,
        display_id: task.conversation.display_id,
        contact_name: task.conversation.contact&.name
      } : nil,
      created_at: task.created_at
    }
  end
end
