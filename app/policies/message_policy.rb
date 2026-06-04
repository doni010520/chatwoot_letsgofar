class MessagePolicy < ApplicationPolicy
  # Window in seconds during which an outgoing message can be edited.
  # Aligned with WhatsApp's native edit window (~15 minutes).
  EDIT_WINDOW_SECONDS = 15 * 60

  # Edit rules:
  # - Administrators can edit any outgoing message within the time window
  # - Agents can edit only their own outgoing messages within the time window
  # - Incoming, private, bot, deleted, failed, or activity messages cannot be edited
  def edit?
    return false unless record.outgoing?
    return false if record.private?
    return false if record.content_attributes&.dig('deleted')
    return false if record.status == 'failed'
    return false if record.created_at < EDIT_WINDOW_SECONDS.seconds.ago

    return true if @account_user&.administrator?

    record.sender_type == 'User' && record.sender_id == @user&.id
  end

  def update?
    edit?
  end
end
