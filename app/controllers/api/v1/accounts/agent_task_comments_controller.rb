# frozen_string_literal: true

class Api::V1::Accounts::AgentTaskCommentsController < Api::V1::Accounts::BaseController
  before_action :set_agent_task
  before_action :set_comment, only: [:destroy]

  def index
    @comments = @agent_task.comments.includes(:user).ordered
    render json: @comments.map { |c| comment_json(c) }
  end

  def create
    @comment = @agent_task.comments.new(comment_params)
    @comment.user = Current.user

    if @comment.save
      render json: comment_json(@comment), status: :created
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_comment_deletion
    @comment.destroy!
    head :no_content
  end

  private

  def set_agent_task
    @agent_task = Current.account.agent_tasks.find(params[:agent_task_id])
    authorize @agent_task, :show?
  end

  def set_comment
    @comment = @agent_task.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def authorize_comment_deletion
    return if @comment.user_id == Current.user.id
    return if Current.user.administrator?

    raise Pundit::NotAuthorizedError
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      created_at: comment.created_at,
      user: {
        id: comment.user.id,
        name: comment.user.name,
        avatar_url: comment.user.avatar_url
      }
    }
  end
end
