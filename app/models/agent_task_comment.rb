# frozen_string_literal: true

class AgentTaskComment < ApplicationRecord
  belongs_to :agent_task, touch: true
  belongs_to :user

  # Validações
  validates :content, presence: true, length: { maximum: 5000 }

  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }
end
