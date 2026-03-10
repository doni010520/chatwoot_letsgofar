# frozen_string_literal: true

class AgentTaskItem < ApplicationRecord
  belongs_to :agent_task, touch: true

  # Validações
  validates :title, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  # Callbacks
  before_create :set_position
  after_update :update_task_status_if_needed

  def toggle!
    update!(completed: !completed)
  end

  def complete!
    update!(completed: true)
  end

  def uncomplete!
    update!(completed: false)
  end

  private

  def set_position
    self.position ||= agent_task.items.maximum(:position).to_i + 1
  end

  def update_task_status_if_needed
    # Se marcou como concluído e a tarefa está pendente, muda para "em andamento"
    if completed? && saved_change_to_completed? && agent_task.status == 'pending'
      agent_task.update_column(:status, 'in_progress')
    end
  end
end
