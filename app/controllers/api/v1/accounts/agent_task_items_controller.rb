# frozen_string_literal: true

class Api::V1::Accounts::AgentTaskItemsController < Api::V1::Accounts::BaseController
  before_action :set_agent_task
  before_action :set_item, only: [:update, :destroy, :toggle]

  def create
    @item = @agent_task.items.new(item_params)

    if @item.save
      render json: item_json(@item), status: :created
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      render json: item_json(@item)
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy!
    head :no_content
  end

  def toggle
    @item.toggle!
    
    # Retorna a tarefa atualizada também
    render json: item_json(@item)
  end

  def reorder
    params[:items].each_with_index do |item_id, index|
      @agent_task.items.find(item_id).update!(position: index)
    end
    head :ok
  end

  private

  def set_agent_task
    @agent_task = Current.account.agent_tasks.find(params[:agent_task_id])
    authorize @agent_task, :update?
  end

  def set_item
    @item = @agent_task.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:title, :completed, :position)
  end

  def item_json(item)
    {
      id: item.id,
      title: item.title,
      completed: item.completed,
      position: item.position,
      created_at: item.created_at,
      updated_at: item.updated_at
    }
  end
end
