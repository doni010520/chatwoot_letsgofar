# frozen_string_literal: true

class Api::V1::Accounts::Kanban::StagesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline
  before_action :set_stage, only: %i[show update destroy reorder]

  def index
    @stages = @pipeline.kanban_stages.ordered
    render json: @stages, each_serializer: KanbanStageSerializer
  end

  def show
    render json: @stage, serializer: KanbanStageSerializer
  end

  def create
    @stage = @pipeline.kanban_stages.new(stage_params)

    if @stage.save
      render json: @stage, serializer: KanbanStageSerializer, status: :created
    else
      render json: { errors: @stage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @stage.update(stage_params)
      render json: @stage, serializer: KanbanStageSerializer
    else
      render json: { errors: @stage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @stage.destroy!
    head :no_content
  end

  def reorder
    new_position = params[:position].to_i
    @stage.reorder_to(new_position)

    render json: @pipeline.kanban_stages.ordered, each_serializer: KanbanStageSerializer
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def set_stage
    @stage = @pipeline.kanban_stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :position, :color)
  end
end