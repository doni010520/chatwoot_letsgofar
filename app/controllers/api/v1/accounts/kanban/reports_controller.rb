# frozen_string_literal: true

class Api::V1::Accounts::Kanban::ReportsController < Api::V1::Accounts::Kanban::BaseController
  before_action :set_pipeline
  before_action :set_date_range

  def summary
    stages = @pipeline.kanban_stages.ordered

    funnel_data = stages.map do |stage|
      conversations = stage_conversations(stage)
      {
        stage_id: stage.id,
        stage_name: stage.name,
        stage_color: stage.color,
        count: conversations.count,
        value: conversations.sum(:deal_value).to_f
      }
    end

    won_conversations = pipeline_conversations.where(closed_won: true)
    lost_conversations = pipeline_conversations.where(closed_won: false)
    open_conversations = pipeline_conversations.where(closed_won: nil)

    render json: {
      pipeline: {
        id: @pipeline.id,
        name: @pipeline.name
      },
      period: {
        start_date: @start_date,
        end_date: @end_date
      },
      funnel: funnel_data,
      totals: {
        total_count: pipeline_conversations.count,
        total_value: pipeline_conversations.sum(:deal_value).to_f,
        won_count: won_conversations.count,
        won_value: won_conversations.sum(:deal_value).to_f,
        lost_count: lost_conversations.count,
        lost_value: lost_conversations.sum(:deal_value).to_f,
        open_count: open_conversations.count,
        open_value: open_conversations.sum(:deal_value).to_f,
        conversion_rate: calculate_conversion_rate(won_conversations.count, lost_conversations.count)
      },
      stage_conversions: calculate_stage_conversions(stages)
    }
  end

  def won_lost_by_period
    won = pipeline_conversations
      .where(closed_won: true)
      .group_by_day(:closed_at, range: @start_date..@end_date)
      .count

    lost = pipeline_conversations
      .where(closed_won: false)
      .group_by_day(:closed_at, range: @start_date..@end_date)
      .count

    won_value = pipeline_conversations
      .where(closed_won: true)
      .group_by_day(:closed_at, range: @start_date..@end_date)
      .sum(:deal_value)

    render json: {
      won: won.map { |date, count| { date: date, count: count, value: won_value[date].to_f } },
      lost: lost.map { |date, count| { date: date, count: count } }
    }
  end

  def loss_reasons
    reasons = pipeline_conversations
      .where(closed_won: false)
      .where.not(closed_reason: nil)
      .group(:closed_reason)
      .count
      .sort_by { |_, count| -count }

    total = reasons.sum { |_, count| count }

    render json: {
      reasons: reasons.map do |reason, count|
        {
          reason: reason,
          count: count,
          percentage: total > 0 ? ((count.to_f / total) * 100).round(1) : 0
        }
      end,
      total: total
    }
  end

  def top_performers
    won_conversations = pipeline_conversations.where(closed_won: true)
    won_conversation_ids = won_conversations.pluck(:id)

    # Primary source: KanbanActivity records that track who actually marked the deal as won
    activity_records = KanbanActivity
      .where(activity_type: 'marked_won', conversation_id: won_conversation_ids)
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
      .where.not(user_id: nil)

    # Find conversations covered by activity records
    conversations_with_activity = activity_records.pluck(:conversation_id).uniq

    # Aggregate from activity records: group by the user who marked as won
    activity_stats = activity_records
      .joins('INNER JOIN conversations ON conversations.id = kanban_activities.conversation_id')
      .joins('INNER JOIN users ON users.id = kanban_activities.user_id')
      .group('users.id', 'users.name')
      .pluck(
        Arel.sql('users.id'),
        Arel.sql('users.name'),
        Arel.sql('COUNT(DISTINCT kanban_activities.conversation_id)'),
        Arel.sql('SUM(conversations.deal_value)')
      )

    # Fallback: legacy conversations without a marked_won activity, attribute to current assignee
    legacy_conversation_ids = won_conversation_ids - conversations_with_activity
    legacy_stats = if legacy_conversation_ids.any?
                     Conversation
                       .where(id: legacy_conversation_ids)
                       .where.not(assignee_id: nil)
                       .joins(:assignee)
                       .group('users.id', 'users.name')
                       .pluck(
                         Arel.sql('users.id'),
                         Arel.sql('users.name'),
                         Arel.sql('COUNT(*)'),
                         Arel.sql('SUM(deal_value)')
                       )
                   else
                     []
                   end

    # Merge both sources into a single hash keyed by user id
    merged = {}
    (activity_stats + legacy_stats).each do |user_id, user_name, count, value|
      entry = merged[user_id] ||= { id: user_id, name: user_name, won_count: 0, total_value: 0.0 }
      entry[:won_count] += count.to_i
      entry[:total_value] += value.to_f
    end

    performers = merged.values.sort_by { |p| -p[:won_count] }.first(10)

    render json: { performers: performers }
  end

  private

  def set_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def set_date_range
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
  end

  def pipeline_conversations
    @pipeline_conversations ||= Current.account.conversations
      .joins(:kanban_stage)
      .where(kanban_stages: { kanban_pipeline_id: @pipeline.id })
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end

  def stage_conversations(stage)
    Current.account.conversations
      .where(kanban_stage_id: stage.id)
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end

  def calculate_conversion_rate(won, lost)
    total = won + lost
    return 0 if total.zero?
    ((won.to_f / total) * 100).round(1)
  end

  def calculate_stage_conversions(stages)
    conversions = []
    stages.each_with_index do |stage, index|
      next if index == 0
      
      prev_stage = stages[index - 1]
      prev_count = stage_conversations(prev_stage).count
      curr_count = stage_conversations(stage).count
      
      rate = prev_count > 0 ? ((curr_count.to_f / prev_count) * 100).round(1) : 0
      
      conversions << {
        from_stage: prev_stage.name,
        to_stage: stage.name,
        from_count: prev_count,
        to_count: curr_count,
        conversion_rate: rate
      }
    end
    conversions
  end
end
