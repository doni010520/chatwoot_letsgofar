# frozen_string_literal: true

class AgentTaskLabel < ApplicationRecord
  belongs_to :agent_task
  belongs_to :label

  # Validações
  validates :label_id, uniqueness: { scope: :agent_task_id, message: 'já está associada a esta tarefa' }

  # Validação para garantir que o label pertence à mesma conta
  validate :label_belongs_to_same_account

  private

  def label_belongs_to_same_account
    return unless agent_task && label

    return if agent_task.account_id == label.account_id

    errors.add(:label, 'deve pertencer à mesma conta da tarefa')
  end
end
