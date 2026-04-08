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

  # Atributo para armazenar o usuário que está fazendo a alteração
  attr_accessor :current_user

  # Callbacks
  before_create :set_position
  after_create :log_item_created
  after_update :log_item_changes
  after_destroy :log_item_removed
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

  def log_item_created
    return unless current_user

    agent_task.activities.create!(
      user: current_user,
      action: 'item_added',
      new_value: title
    )
  end

  def log_item_changes
    return unless current_user

    # Verificar se completed mudou
    if saved_change_to_completed?
      old_completed, new_completed = saved_change_to_completed
      action = new_completed ? 'item_completed' : 'item_reopened'
      agent_task.activities.create!(
        user: current_user,
        action: action,
        new_value: title
      )
    end

    # Verificar se título mudou
    if saved_change_to_title?
      old_title, new_title = saved_change_to_title
      agent_task.activities.create!(
        user: current_user,
        action: 'item_updated',
        old_value: old_title,
        new_value: new_title
      )
    end
  end

  def log_item_removed
    return unless current_user

    agent_task.activities.create!(
      user: current_user,
      action: 'item_removed',
      old_value: title
    )
  end

  def update_task_status_if_needed
    return unless saved_change_to_completed?
    
    agent_task.items.reload
    
    total_items = agent_task.items.count
    completed_items = agent_task.items.completed.count
    
    return if total_items == 0
    
    if completed_items == total_items && agent_task.status != 'completed'
      agent_task.update_column(:status, 'completed')
    elsif completed_items == 0 && agent_task.status == 'in_progress'
      agent_task.update_column(:status, 'pending')
    elsif completed_items > 0 && completed_items < total_items && agent_task.status == 'pending'
      agent_task.update_column(:status, 'in_progress')
    end
  end
end
