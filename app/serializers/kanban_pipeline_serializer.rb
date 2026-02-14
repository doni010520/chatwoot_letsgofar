# frozen_string_literal: true

class KanbanPipelineSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :description,
             :pipeline_type,
             :is_default,
             :created_at,
             :updated_at

  has_many :kanban_stages, serializer: KanbanStageSerializer
end