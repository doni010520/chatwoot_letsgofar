# frozen_string_literal: true

class AgentTask < ApplicationRecord
  # Relacionamentos obrigatórios
  belongs_to :account
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true

  # Vínculos opcionais
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true
  belongs_to :kanban_pipeline, optional: true

  # Relacionamentos dependentes
  has_many :items, class_name: 'AgentTaskItem', dependent: :destroy
  has_many :comments, class_name: 'AgentTaskComment', dependent: :destroy
  has_many :task_labels, class_name: 'AgentTaskLabel', dependent: :destroy
  has_many :labels, through: :task_labels

  # Anexos
  has_many_attached :files

  # Aceita nested attributes
  accepts_nested_attributes_for :items, allow_destroy: true

  # Constantes
  PRIORITIES = %w[low medium high urgent].freeze
  STATUSES = %w[pending in_progress completed cancelled].freeze

  # Validações
  validates :title, presence: true, length: { maximum: 255 }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :description, length: { maximum: 5000 }, allow_nil: true

  # Scopes de status
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :active, -> { where(status: %w[pending in_progress]) }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  # Scopes de data
  scope :overdue, -> { active.where('due_date < ?', Date.current) }
  scope :due_today, -> { active.where(due_date: Date.current) }
  scope :due_tomorrow, -> { active.where(due_date: Date.current + 1.day) }
  scope :due_this_week, -> { active.where(due_date: Date.current..Date.current.end_of_week) }
  scope :due_next_week, -> { active.where(due_date: (Date.current.end_of_week + 1.day)..(Date.current.end_of_week + 1.week)) }
  scope :due_this_month, -> { active.where(due_date: Date.current..Date.current.end_of_month) }
  scope :no_due_date, -> { where(due_date: nil) }
  scope :upcoming, -> { active.where('due_date >= ?', Date.current).order(due_date: :asc) }
  scope :with_due_date, -> { where.not(due_date: nil) }

  # Scopes de vínculo
  scope :with_contact, -> { where.not(contact_id: nil) }
  scope :with_conversation, -> { where.not(conversation_id: nil) }
  scope :with_pipeline, -> { where.not(kanban_pipeline_id: nil) }
  scope :standalone, -> { where(contact_id: nil, conversation_id: nil, kanban_pipeline_id: nil) }
  scope :linked, -> { where.not(contact_id: nil).or(where.not(conversation_id: nil)).or(where.not(kanban_pipeline_id: nil)) }

  # Scopes de atribuição
  scope :assigned_to_user, ->(user_id) { where(assigned_to_id: user_id) }
  scope :created_by_user, ->(user_id) { where(created_by_id: user_id) }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :assigned, -> { where.not(assigned_to_id: nil) }

  # Scopes de prioridade
  scope :priority_urgent, -> { where(priority: 'urgent') }
  scope :priority_high, -> { where(priority: 'high') }
  scope :priority_medium, -> { where(priority: 'medium') }
  scope :priority_low, -> { where(priority: 'low') }

  # Ordenação por prioridade
  scope :by_priority, lambda {
    order(Arel.sql("CASE priority
      WHEN 'urgent' THEN 1
      WHEN 'high' THEN 2
      WHEN 'medium' THEN 3
      WHEN 'low' THEN 4
    END"))
  }

  # Ordenação por status
  scope :by_status, lambda {
    order(Arel.sql("CASE status
      WHEN 'in_progress' THEN 1
      WHEN 'pending' THEN 2
      WHEN 'completed' THEN 3
      WHEN 'cancelled' THEN 4
    END"))
  }

  # Scope para calendário
  scope :for_calendar, ->(start_date, end_date) { where(due_date: start_date..end_date) }

  # Scope para busca
  scope :search, lambda { |query|
    return all if query.blank?

    where('title ILIKE :query OR description ILIKE :query', query: "%#{query}%")
  }

  # Métodos de ação
  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  def start!
    update!(status: 'in_progress', started_at: Time.current)
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def reopen!
    update!(status: 'pending', completed_at: nil, started_at: nil)
  end

  def assign_to!(user)
    update!(assigned_to: user)
  end

  def unassign!
    update!(assigned_to: nil)
  end

  # Métodos de verificação
  def overdue?
    due_date.present? && due_date < Date.current && active?
  end

  def due_today?
    due_date == Date.current
  end

  def due_soon?
    due_date.present? && due_date <= Date.current + 3.days && active?
  end

  def active?
    %w[pending in_progress].include?(status)
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def has_checklist?
    items.any?
  end

  def linked?
    contact_id.present? || conversation_id.present? || kanban_pipeline_id.present?
  end

  # Métodos de progresso
  def progress_percentage
    return 0 if items.empty?

    completed_count = items.where(completed: true).count
    (completed_count.to_f / items.count * 100).round
  end

  def items_summary
    return nil if items.empty?

    completed_count = items.where(completed: true).count
    "#{completed_count}/#{items.count}"
  end

  # Método para due_datetime combinado
  def due_datetime
    return nil unless due_date

    if due_time
      Time.zone.local(due_date.year, due_date.month, due_date.day, due_time.hour, due_time.min)
    else
      due_date.end_of_day
    end
  end

  # Classe methods para estatísticas
  class << self
    # Agora recebe um scope base já filtrado por permissões
    def stats_for_scope(base_scope, user_id = nil)
      {
        by_status: {
          pending: base_scope.pending.count,
          in_progress: base_scope.in_progress.count,
          completed: base_scope.completed.count,
          cancelled: base_scope.cancelled.count
        },
        by_priority: {
          urgent: base_scope.active.priority_urgent.count,
          high: base_scope.active.priority_high.count,
          medium: base_scope.active.priority_medium.count,
          low: base_scope.active.priority_low.count
        },
        overdue: base_scope.overdue.count,
        due_today: base_scope.due_today.count,
        due_this_week: base_scope.due_this_week.count,
        unassigned: base_scope.active.unassigned.count,
        my_tasks: user_id ? base_scope.active.assigned_to_user(user_id).count : 0,
        total_active: base_scope.active.count
      }
    end

    # Mantém compatibilidade mas agora é só um wrapper
    def stats_for_account(account_id, user_id = nil)
      stats_for_scope(where(account_id: account_id), user_id)
    end

    # Agora recebe um scope base já filtrado por permissões
    def calendar_data_for_scope(base_scope, start_date, end_date)
      tasks = base_scope
              .for_calendar(start_date, end_date)
              .includes(:assigned_to, :labels)
              .order(:due_date, :due_time)

      tasks.group_by(&:due_date).transform_values do |day_tasks|
        day_tasks.map do |task|
          {
            id: task.id,
            title: task.title,
            priority: task.priority,
            status: task.status,
            due_time: task.due_time&.strftime('%H:%M'),
            assigned_to: task.assigned_to&.slice(:id, :name, :avatar_url),
            labels: task.labels.map { |l| { id: l.id, title: l.title, color: l.color } }
          }
        end
      end
    end

    # Mantém compatibilidade
    def calendar_data(account_id, start_date, end_date)
      calendar_data_for_scope(where(account_id: account_id), start_date, end_date)
    end
  end
end
