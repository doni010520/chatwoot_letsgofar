# frozen_string_literal: true

class Api::V1::Accounts::Kanban::TasksController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_conversation
  before_action :set_task, only: [:show, :update, :destroy, :complete]

  def index
    @tasks = @conversation.kanban_tasks
                          .includes(:user, :assigned_to)
                          .by_priority
                          .order(created_at: :desc)

    render json: @tasks.map { |t| task_json(t) }
  end

  def show
    render json: task_json(@task)
  end

  def create
    @task = @conversation.kanban_tasks.new(task_params)
    @task.account_id = Current.account.id
    @task.user_id = Current.user.id

    if @task.save
      render json: task_json(@task), status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: task_json(@task)
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    head :ok
  end

  def complete
    @task.complete!
    render json: task_json(@task)
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def set_task
    @task = @conversation.kanban_tasks.find(params[:id])
  end

  def task_params
    params.permit(:title, :description, :due_at, :priority, :status, :assigned_to_id)
  end

  def task_json(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      due_at: task.due_at,
      completed_at: task.completed_at,
      priority: task.priority,
      status: task.status,
      overdue: task.overdue?,
      user: task.user ? {
        id: task.user.id,
        name: task.user.name
      } : nil,
      assigned_to: task.assigned_to ? {
        id: task.assigned_to.id,
        name: task.assigned_to.name
      } : nil,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end
end
