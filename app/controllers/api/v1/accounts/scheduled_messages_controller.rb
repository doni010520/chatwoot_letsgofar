class Api::V1::Accounts::ScheduledMessagesController < Api::V1::Accounts::BaseController
  before_action :set_message, only: [:update, :destroy]

  def index
    @messages = Current.account.scheduled_messages
      .includes(:contact, :user)
      .where(filter_params)
      .order(order_params)
    
    render json: @messages.map { |msg| message_json(msg) }
  end

  def create
    @message = Current.account.scheduled_messages.new(message_params)
    @message.user = Current.user
    
    if @message.save
      render json: message_json(@message), status: :created
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @message.update(message_params)
      render json: message_json(@message)
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy
    head :no_content
  end

  private

  def set_message
    @message = Current.account.scheduled_messages.find(params[:id])
  end

  def message_params
    params.require(:scheduled_message).permit(:contact_id, :content, :scheduled_at)
  end

  def filter_params
    filters = {}
    filters[:status] = params[:status] if params[:status].present?
    filters
  end

  def order_params
    case params[:sortBy]
    when 'date_desc'
      { scheduled_at: :desc }
    when 'contact'
      { contacts: { name: :asc } }
    else
      { scheduled_at: :asc }
    end
  end

  def message_json(msg)
    {
      id: msg.id,
      content: msg.content,
      scheduled_at: msg.scheduled_at,
      status: msg.status,
      contact: {
        id: msg.contact.id,
        name: msg.contact.name,
        avatar: msg.contact.avatar_url
      },
      user: {
        id: msg.user.id,
        name: msg.user.name
      },
      created_at: msg.created_at
    }
  end
end
