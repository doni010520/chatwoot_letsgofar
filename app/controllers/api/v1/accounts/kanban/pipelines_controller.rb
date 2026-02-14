# frozen_string_literal: true

class Api::V1::Accounts::Kanban::PipelinesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline, only: %i[show update destroy board]

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

  def board
    stages = @pipeline.kanban_stages.ordered

    board_data = stages.map do |stage|
      items = if @pipeline.pipeline_type == 'contacts'
                stage.contacts.limit(50)
              else
                stage.conversations.includes(:contact, :assignee).limit(50)
              end

      {
        stage: stage_json(stage),
        items: items.map { |item| item_json(item, @pipeline.pipeline_type) },
        totals: {
          count: items.size,
          value: 0
        }
      }
    end

    render json: {
      pipeline: pipeline_json(@pipeline),
      board: board_data,
      totals: {
        count: board_data.sum { |col| col[:totals][:count] },
        value: 0
      }
    }
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
      kanban_stages: pipeline.kanban_stages.order(:position).map { |s| stage_json(s) }
    }
  end

  def stage_json(stage)
    {
      id: stage.id,
      name: stage.name,
      color: stage.color,
      position: stage.position
    }
  end

  def item_json(item, pipeline_type)
    if pipeline_type == 'contacts'
      {
        id: item.id,
        name: item.name,
        email: item.email,
        phone_number: item.phone_number,
        kanban_stage_id: item.kanban_stage_id
      }
    else
      {
        id: item.id,
        display_id: item.display_id,
        status: item.status,
        kanban_stage_id: item.kanban_stage_id,
        contact: item.contact ? {
          id: item.contact.id,
          name: item.contact.name,
          email: item.contact.email
        } : nil,
        assignee: item.assignee ? {
          id: item.assignee.id,
          name: item.assignee.name
        } : nil,
        last_activity_at: item.last_activity_at
      }
    end
  end
end
