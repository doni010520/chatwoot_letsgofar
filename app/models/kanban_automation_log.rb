# app/models/kanban_automation_log.rb
class KanbanAutomationLog < ApplicationRecord
  # Associations
  belongs_to :kanban_automation
  belongs_to :conversation, optional: true

  # Validations
  validates :status, inclusion: { in: %w[pending running success failed] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_automation, ->(id) { where(kanban_automation_id: id) }

  # Status constants
  STATUSES = {
    'pending' => 'Pendente',
    'running' => 'Executando',
    'success' => 'Sucesso',
    'failed' => 'Falhou'
  }.freeze

  def status_label
    STATUSES[status] || status
  end

  def mark_running!
    update(status: 'running')
  end

  def mark_success!(actions_results)
    update(
      status: 'success',
      actions_executed: actions_results,
      executed_at: Time.current
    )
  end

  def mark_failed!(error)
    update(
      status: 'failed',
      error_message: error,
      executed_at: Time.current
    )
  end

  def duration
    return nil unless executed_at && created_at

    executed_at - created_at
  end
end
