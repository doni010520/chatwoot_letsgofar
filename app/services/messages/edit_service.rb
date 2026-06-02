# frozen_string_literal: true

# Service to edit an existing outgoing message's content while preserving
# history. Triggers the `message.updated` webhook which the n8n bridge
# workflow uses to call UAzapi `/message/edit`.
class Messages::EditService
  MAX_CONTENT_LENGTH = 4096
  MAX_HISTORY_ENTRIES = 10

  pattr_initialize [:message!, :new_content!, :editor!]

  def perform
    validate!

    original = message.content
    history = Array(message.content_attributes&.dig('edit_history'))

    history << {
      'content' => original,
      'edited_at' => Time.current.utc.iso8601,
      'edited_by_id' => editor.id,
      'edited_by_name' => editor.name
    }
    # Keep history bounded to avoid unbounded JSONB growth
    history = history.last(MAX_HISTORY_ENTRIES)

    new_attributes = (message.content_attributes || {}).merge(
      'edited' => true,
      'edited_at' => Time.current.utc.iso8601,
      'edited_by_id' => editor.id,
      'original_content' => message.content_attributes&.dig('original_content') || original,
      'edit_history' => history
    )

    message.update!(
      content: new_content.to_s.strip,
      content_attributes: new_attributes
    )

    message
  end

  private

  def validate!
    raise ArgumentError, 'Conteúdo não pode ficar vazio' if new_content.to_s.strip.blank?
    raise ArgumentError, "Conteúdo excede #{MAX_CONTENT_LENGTH} caracteres" if new_content.to_s.length > MAX_CONTENT_LENGTH
    raise ArgumentError, 'Conteúdo não foi alterado' if new_content.to_s.strip == message.content.to_s.strip
  end
end
