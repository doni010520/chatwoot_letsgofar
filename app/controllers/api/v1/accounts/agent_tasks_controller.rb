# frozen_string_literal: true

class Api::V1::Accounts::AgentTasksController < Api::V1::Accounts::BaseController
  before_action :set_agent_task, only: [:show, :update, :destroy, :complete, :start, :cancel, :reopen, :assign]

  def index
    @agent_tasks = filtered_tasks
                   .includes(:created_by, :assigned_to, :contact, :conversation, :labels, :items)
                   .page(params[:page])
                   .per(params[:per_page] || 25)
  end

  def show
    @agent_task
  end

  def create
    @agent_task = Current.account.agent_tasks.new(agent_task_params)
    @agent_task.created_by = Current.user

    if @agent_task.save
      render :show, status: :created
    else
      render json: { errors: @agent_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @agent_task

    if @agent_task.update(agent_task_params)
      render :show
    else
      render json: { errors: @agent_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @agent_task
    @agent_task.destroy!
    head :no_content
  end

  # Ações customizadas
  def complete
    authorize @agent_task
    @agent_task.complete!
    render :show
  end

  def start
    authorize @agent_task
    @agent_task.start!
    render :show
  end

  def cancel
    authorize @agent_task
    @agent_task.cancel!
    render :show
  end

  def reopen
    authorize @agent_task
    @agent_task.reopen!
    render :show
  end

  def assign
    authorize @agent_task

    user_id = params[:user_id]
    if user_id.present?
      user = Current.account.users.find(user_id)
      @agent_task.assign_to!(user)
    else
      @agent_task.unassign!
    end

    render :show
  end

  # Endpoints especiais
  def calendar
    start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    end_date = params[:end_date]&.to_date || Date.current.end_of_month

    @calendar_data = AgentTask.calendar_data(Current.account.id, start_date, end_date)

    render json: {
      data: @calendar_data,
      meta: {
        start_date: start_date,
        end_date: end_date,
        total_tasks: @calendar_data.values.flatten.count
      }
    }
  end

  def stats
    @stats = AgentTask.stats_for_account(Current.account.id, Current.user.id)
    render json: @stats
  end

  def kanban
    @tasks_by_status = {
      pending: filtered_tasks.pending.by_priority.limit(50),
      in_progress: filtered_tasks.in_progress.by_priority.limit(50),
      completed: filtered_tasks.completed.order(completed_at: :desc).limit(20),
      cancelled: filtered_tasks.cancelled.order(updated_at: :desc).limit(10)
    }
  end

  private

  def set_agent_task
    @agent_task = Current.account.agent_tasks.find(params[:id])
    authorize @agent_task
  end

  def agent_task_params
    params.require(:agent_task).permit(
      :title,
      :description,
      :priority,
      :status,
      :due_date,
      :due_time,
      :reminder_at,
      :assigned_to_id,
      :contact_id,
      :conversation_id,
      :kanban_pipeline_id,
      label_ids: [],
      items_attributes: [:id, :title, :completed, :position, :_destroy]
    )
  end

  def filtered_tasks
    tasks = policy_scope(AgentTask)

    # Filtro por status
    tasks = filter_by_status(tasks)

    # Filtro por prioridade
    tasks = tasks.where(priority: params[:priority]) if params[:priority].present?

    # Filtro por atribuição
    tasks = filter_by_assignment(tasks)

    # Filtro por data
    tasks = filter_by_due_date(tasks)

    # Filtro por vínculo
    tasks = filter_by_link(tasks)

    # Filtro por labels
    tasks = filter_by_labels(tasks)

    # Busca por texto
    tasks = tasks.search(params[:q]) if params[:q].present?

    # Ordenação
    apply_sorting(tasks)
  end

  def filter_by_status(tasks)
    case params[:status]
    when 'active'
      tasks.active
    when 'pending'
      tasks.pending
    when 'in_progress'
      tasks.in_progress
    when 'completed'
      tasks.completed
    when 'cancelled'
      tasks.cancelled
    else
      tasks
    end
  end

  def filter_by_assignment(tasks)
    if params[:assigned_to_id].present?
      tasks.assigned_to_user(params[:assigned_to_id])
    elsif params[:created_by_id].present?
      tasks.created_by_user(params[:created_by_id])
    elsif params[:unassigned] == 'true'
      tasks.unassigned
    elsif params[:my_tasks] == 'true'
      tasks.assigned_to_user(Current.user.id)
    else
      tasks
    end
  end

  def filter_by_due_date(tasks)
    case params[:due_date]
    when 'overdue'
      tasks.overdue
    when 'today'
      tasks.due_today
    when 'tomorrow'
      tasks.due_tomorrow
    when 'this_week'
      tasks.due_this_week
    when 'next_week'
      tasks.due_next_week
    when 'this_month'
      tasks.due_this_month
    when 'no_date'
      tasks.no_due_date
    when 'upcoming'
      tasks.upcoming
    else
      if params[:due_date_from].present? && params[:due_date_to].present?
        tasks.where(due_date: params[:due_date_from]..params[:due_date_to])
      elsif params[:due_date_from].present?
        tasks.where('due_date >= ?', params[:due_date_from])
      elsif params[:due_date_to].present?
        tasks.where('due_date <= ?', params[:due_date_to])
      else
        tasks
      end
    end
  end

  def filter_by_link(tasks)
    case params[:linked_to]
    when 'contact'
      tasks.with_contact
    when 'conversation'
      tasks.with_conversation
    when 'pipeline'
      tasks.with_pipeline
    when 'any'
      tasks.linked
    when 'none'
      tasks.standalone
    else
      if params[:contact_id].present?
        tasks.where(contact_id: params[:contact_id])
      elsif params[:conversation_id].present?
        tasks.where(conversation_id: params[:conversation_id])
      elsif params[:kanban_pipeline_id].present?
        tasks.where(kanban_pipeline_id: params[:kanban_pipeline_id])
      else
        tasks
      end
    end
  end

  def filter_by_labels(tasks)
    return tasks unless params[:label_ids].present?

    label_ids = params[:label_ids].is_a?(Array) ? params[:label_ids] : params[:label_ids].split(',')
    tasks.joins(:task_labels).where(agent_task_labels: { label_id: label_ids }).distinct
  end

  def apply_sorting(tasks)
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'

    case sort_by
    when 'due_date'
      tasks.order(Arel.sql("CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, due_date #{sort_order}"))
    when 'priority'
      if sort_order == 'asc'
        tasks.order(Arel.sql("CASE priority WHEN 'low' THEN 1 WHEN 'medium' THEN 2 WHEN 'high' THEN 3 WHEN 'urgent' THEN 4 END"))
      else
        tasks.by_priority
      end
    when 'title'
      tasks.order(title: sort_order)
    when 'status'
      tasks.by_status
    else
      tasks.order(created_at: sort_order)
    end
  end
end
