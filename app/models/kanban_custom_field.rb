# frozen_string_literal: true

class KanbanCustomField < ApplicationRecord
  belongs_to :account
  belongs_to :kanban_pipeline
  has_many :kanban_custom_field_values, dependent: :destroy

  FIELD_TYPES = %w[text textarea number currency select multiselect date checkbox].freeze

  validates :name, presence: true
  validates :field_key, presence: true, uniqueness: { scope: :kanban_pipeline_id }
  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }

  before_validation :generate_field_key, on: :create

  scope :ordered, -> { order(position: :asc) }
  scope :visible_on_card, -> { where(show_on_card: true) }

  def select_options
    options['choices'] || []
  end

  def select_options=(choices)
    self.options = (options || {}).merge('choices' => choices)
  end

  private

  def generate_field_key
    return if field_key.present?

    base_key = name.to_s.parameterize.underscore.first(50)
    self.field_key = base_key

    counter = 1
    while KanbanCustomField.exists?(kanban_pipeline_id: kanban_pipeline_id, field_key: field_key)
      self.field_key = "#{base_key}_#{counter}"
      counter += 1
    end
  end
end
