# frozen_string_literal: true

class KanbanStageSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :position,
             :color,
             :kanban_pipeline_id
end