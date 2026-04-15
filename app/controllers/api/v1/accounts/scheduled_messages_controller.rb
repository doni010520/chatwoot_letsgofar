class Api::V1::Accounts::ScheduledMessagesController < Api::V1::Accounts::BaseController
  before_action :set_message, only: [:update, :destroy, :remove_file]

  def index
    @messages = Current.account.scheduled_messages
      .includes(:contact, :user)
      .where(filter_params)
      .order(order_params)

    render json: @messages.map { |msg| message_json(msg) }
  end

  def create
    @message = Current.account.scheduled_messages.new(message_params_without_files)
    @message.user = Current.user

    if @message.save
      @message.files.attach(params[:scheduled_message][:files]) if params[:scheduled_message][:files].present?
      render json: message_json(@message), status: :created
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  def update
    # Separar files dos outros parametros
    params_hash = message_params_without_files.to_h

    if @message.update(params_hash)
      @message.files.attach(params[:scheduled_message][:files]) if params[:scheduled_message][:files].present?
      render json: message_json(@message)
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy
    head :no_content
  end

  def remove_file
    begin
      attachment = ActiveStorage::Attachment.find(params[:file_id])

      if attachment.record_id == @message.id && attachment.record_type == 'ScheduledMessage'
        attachment.purge
        render json: message_json(@message.reload)
      else
        render json: { error: 'File not found' }, status: :not_found
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'File not found' }, status: :not_found
    end
  end

  private

  def set_message
    @message = Current.account.scheduled_messages.find(params[:id])
  end

  def message_params_without_files
    params.require(:scheduled_message).permit(:contact_id, :conversation_id, :content, :scheduled_at)
  end

  def filter_params
    filters = {}
    filters[:status] = params[:status] if params[:status].present?
    filters[:conversation_id] = params[:conversation_id] if params[:conversation_id].present?
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
      conversation_id: msg.conversation_id,
      files: msg.files.map { |file|
        {
          id: file.id,
          filename: file.filename.to_s,
          content_type: file.content_type,
          byte_size: file.byte_size,
          url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
        }
      },
      created_at: msg.created_at
    }
  end
end
