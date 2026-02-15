# frozen_string_literal: true

class KanbanTask < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user, optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true

  PRIORITIES = %w[low medium high urgent].freeze
  STATUSES = %w[pending in_progress completed cancelled].freeze

  validates :title, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: %w[pending in_progress]) }
  scope :completed, -> { where(status: 'completed') }
  scope :overdue, -> { pending.where('due_at < ?', Time.current) }
  scope :due_today, -> { pending.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :upcoming, -> { pending.where('due_at > ?', Time.current).order(due_at: :asc) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END")) }

  after_create :log_activity_created
  after_update :log_activity_completed, if: :saved_change_to_status?

  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  def overdue?
    due_at.present? && due_at < Time.current && !completed?
  end

  def completed?
    status == 'completed'
  end

  private

  def log_activity_created
    KanbanActivity.log(
      conversation,
      'task_created',
      user: user,
      title: "Tarefa criada: #{title}",
      metadata: { task_id: id, due_at: due_at }
    )
  end

  def log_activity_completed
    return unless status == 'completed'

    KanbanActivity.log(
      conversation,
      'task_completed',
      user: user,
      title: "Tarefa concluída: #{title}",
      metadata: { task_id: id }
    )
  end
end
