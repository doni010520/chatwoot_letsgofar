# frozen_string_literal: true

class AgentTaskItem < ApplicationRecord
  belongs_to :agent_task, touch: true

  # Validações
  validates :title, presence: true, length: { maximum: 1000 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  # Callbacks
  before_create :set_position
  after_save :update_task_status_if_needed

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
    return unless saved_change_to_completed? # Só executa se completed mudou
    
    agent_task.items.reload
    
    total_items = agent_task.items.count
    completed_items = agent_task.items.completed.count
    
    return if total_items == 0
    
    # Todas marcadas → Concluído
    if completed_items == total_items && agent_task.status != 'completed'
      agent_task.update_column(:status, 'completed')
    # Nenhuma marcada → Pendente
    elsif completed_items == 0 && agent_task.status == 'in_progress'
      agent_task.update_column(:status, 'pending')
    # Algumas marcadas → Em andamento
    elsif completed_items > 0 && completed_items < total_items && agent_task.status == 'pending'
      agent_task.update_column(:status, 'in_progress')
    end
  end 
end 
