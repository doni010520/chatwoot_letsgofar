# frozen_string_literal: true

class Api::V1::Accounts::AgentTaskLabelsController < Api::V1::Accounts::BaseController
  before_action :set_agent_task

  def create
    label = Current.account.labels.find(params[:label_id])
    @task_label = @agent_task.task_labels.find_or_create_by!(label: label)

    render json: {
      id: @task_label.id,
      label: {
        id: label.id,
        title: label.title,
        color: label.color
      }
    }, status: :created
  end

  def destroy
    @task_label = @agent_task.task_labels.find_by!(label_id: params[:id])
    @task_label.destroy!
    head :no_content
  end

  private

  def set_agent_task
    @agent_task = Current.account.agent_tasks.find(params[:agent_task_id])
    authorize @agent_task, :update?
  end
end
