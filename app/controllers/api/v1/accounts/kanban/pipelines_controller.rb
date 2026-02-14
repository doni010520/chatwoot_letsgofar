# frozen_string_literal: true

class Api::V1::Accounts::Kanban::PipelinesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline, only: %i[show update destroy]

  def index
    @pipelines = Current.account.kanban_pipelines.includes(:kanban_stages).default_first
    render json: pipelines_json(@pipelines)
  end

  def show
    render json: pipeline_json(@pipeline)
  end

  def create
    @pipeline = Current.account.kanban_pipelines.new(pipeline_params)
    if @pipeline.save
      render json: pipeline_json(@pipeline), status: :created
    else
      render json: { errors: @pipeline.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pipeline.update(pipeline_params)
      render json: pipeline_json(@pipeline)
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

  def pipelines_json(pipelines)
    pipelines.map { |p| pipeline_json(p) }
  end

  def pipeline_json(pipeline)
    {
      id: pipeline.id,
      name: pipeline.name,
      description: pipeline.description,
      pipeline_type: pipeline.pipeline_type,
      is_default: pipeline.is_default,
      created_at: pipeline.created_at,
      updated_at: pipeline.updated_at,
      kanban_stages: pipeline.kanban_stages.order(:position).map do |stage|
        {
          id: stage.id,
          name: stage.name,
          color: stage.color,
          position: stage.position
        }
      end
    }
  end
end
