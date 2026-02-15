# frozen_string_literal: true

class KanbanPipeline < ApplicationRecord
  belongs_to :account
  has_many :kanban_stages, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :kanban_pipeline
  has_many :kanban_custom_fields, -> { order(position: :asc) }, dependent: :destroy
  has_many :kanban_automation, dependet: :destroy
  
  enum pipeline_type: { conversations: 0, contacts: 1, both: 2 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :pipeline_type, presence: true

  before_save :ensure_single_default
  after_create :create_default_stages

  scope :for_conversations, -> { where(pipeline_type: %i[conversations both]) }
  scope :for_contacts, -> { where(pipeline_type: %i[contacts both]) }
  scope :default_first, -> { order(is_default: :desc, created_at: :asc) }

  def conversations
    Conversation.where(kanban_stage_id: kanban_stages.pluck(:id))
  end

  def contacts
    Contact.where(kanban_stage_id: kanban_stages.pluck(:id))
  end

  private

  def ensure_single_default
    return unless is_default_changed? && is_default?

    account.kanban_pipelines
           .where(is_default: true)
           .where.not(id: id)
           .update_all(is_default: false)
  end

  def create_default_stages
    default_stages = [
      { name: 'Leads', position: 0, color: '#6366F1' },
      { name: 'Qualificação', position: 1, color: '#F59E0B' },
      { name: 'Negociação', position: 2, color: '#3B82F6' },
      { name: 'Fechamento', position: 3, color: '#10B981' }
    ]

    default_stages.each do |stage_attrs|
      kanban_stages.create!(stage_attrs)
    end
  end

end

