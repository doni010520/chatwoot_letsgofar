# frozen_string_literal: true

json.partial! 'api/v1/accounts/broadcasts/broadcast', broadcast: @broadcast

json.recipients @broadcast.broadcast_recipients.ordered do |recipient|
  json.id recipient.id
  json.phone recipient.phone
  json.name recipient.name
  json.status recipient.status
  json.error recipient.error
  json.conversation_id recipient.conversation_id
  json.sent_at recipient.sent_at
end
