# frozen_string_literal: true

class Api::V1::Accounts::Kanban::CustomFieldsController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline
  before_action :set_custom_field, only: [:show, :update, :destroy, :reorder]

  def index
    @custom_fields = @pipeline.kanban_custom_fields.ordered
    render json: @custom_fields.map { |cf| custom_field_json(cf) }
  end

  def show
    render json: custom_field_json(@custom_field)
  end

  def create
    @custom_field = @pipeline.kanban_custom_fields.new(custom_field_params)
    @custom_field.account_id = Current.account.id

    if @custom_field.save
      render json: custom_field_json(@custom_field), status: :created
    else
      render json: { errors: @custom_field.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @custom_field.update(custom_field_params)
      render json: custom_field_json(@custom_field)
    else
      render json: { errors: @custom_field.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_field.destroy
    head :ok
  end

  def reorder
    @custom_field.update(position: params[:position])
    render json: custom_field_json(@custom_field)
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def set_custom_field
    @custom_field = @pipeline.kanban_custom_fields.find(params[:id])
  end

  def custom_field_params
    params.permit(:name, :field_key, :field_type, :description, :required, :show_on_card, :position, options: {}, select_options: [])
  end

  def custom_field_json(field)
    {
      id: field.id,
      name: field.name,
      field_key: field.field_key,
      field_type: field.field_type,
      description: field.description,
      options: field.options,
      select_options: field.select_options,
      required: field.required,
      show_on_card: field.show_on_card,
      position: field.position,
      created_at: field.created_at
    }
  end
end
