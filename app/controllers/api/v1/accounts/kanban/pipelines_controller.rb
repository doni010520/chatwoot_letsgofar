# frozen_string_literal: true

class Api::V1::Accounts::Kanban::PipelinesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline, only: %i[show update destroy]

  def index
    @pipelines = Current.account.kanban_pipelines.includes(:kanban_stages).default_first
    render json: @pipelines, each_serializer: KanbanPipelineSerializer
  end

  def show
    render json: @pipeline, serializer: KanbanPipelineSerializer
  end

  def create
    @pipeline = Current.account.kanban_pipelines.new(pipeline_params)

    if @pipeline.save
      render json: @pipeline, serializer: KanbanPipelineSerializer, status: :created
    else
      render json: { errors: @pipeline.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pipeline.update(pipeline_params)
      render json: @pipeline, serializer: KanbanPipelineSerializer
    else
      render json: { errors: @pipeline.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @pipeline.destroy!
    head :no_content
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :description, :pipeline_type, :is_default)
  end
end