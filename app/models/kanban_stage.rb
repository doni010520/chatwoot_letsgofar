# frozen_string_literal: true

class KanbanStage < ApplicationRecord
  belongs_to :kanban_pipeline, inverse_of: :kanban_stages
  has_many :conversations, dependent: :nullify
  has_many :contacts, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :kanban_pipeline_id }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'deve ser uma cor hexadecimal válida' }

  before_validation :set_default_position, on: :create

  scope :ordered, -> { order(position: :asc) }

  delegate :account, to: :kanban_pipeline

  def totals_for_conversations
    convs = conversations
    {
      count: convs.count,
      value: calculate_total_value(convs)
    }
  end

  def totals_for_contacts
    conts = contacts
    {
      count: conts.count,
      value: calculate_total_value(conts)
    }
  end

  def reorder_to(new_position)
    return if position == new_position

    transaction do
      if new_position > position
        kanban_pipeline.kanban_stages
                       .where('position > ? AND position <= ?', position, new_position)
                       .update_all('position = position - 1')
      else
        kanban_pipeline.kanban_stages
                       .where('position >= ? AND position < ?', new_position, position)
                       .update_all('position = position + 1')
      end

      update!(position: new_position)
    end
  end

  private

  def set_default_position
    return if position.present? && position.positive?

    max_position = kanban_pipeline&.kanban_stages&.maximum(:position) || -1
    self.position = max_position + 1
  end

  def calculate_total_value(records)
    records.sum do |record|
      record.custom_attributes&.dig('valor_negocio').to_f
    rescue StandardError
      0
    end
  end
end