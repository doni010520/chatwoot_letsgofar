# frozen_string_literal: true

class Api::V1::Accounts::Kanban::ActivitiesController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_conversation
  before_action :set_activity, only: [:destroy]

  def index
    @activities = @conversation.kanban_activities
                               .includes(:user)
                               .recent
                               .limit(50)

    render json: @activities.map { |a| activity_json(a) }
  end

  def create
    @activity = @conversation.kanban_activities.new(activity_params)
    @activity.account_id = Current.account.id
    @activity.user_id = Current.user.id

    if @activity.save
      render json: activity_json(@activity), status: :created
    else
      render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    head :ok
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def set_activity
    @activity = @conversation.kanban_activities.find(params[:id])
  end

  def activity_params
    params.permit(:activity_type, :title, :description, metadata: {})
  end

  def activity_json(activity)
    {
      id: activity.id,
      activity_type: activity.activity_type,
      title: activity.title,
      description: activity.description,
      metadata: activity.metadata,
      user: activity.user ? {
        id: activity.user.id,
        name: activity.user.name,
        avatar_url: activity.user.avatar_url
      } : nil,
      created_at: activity.created_at
    }
  end
end
