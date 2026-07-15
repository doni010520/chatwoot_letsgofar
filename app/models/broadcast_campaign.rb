# frozen_string_literal: true

class BroadcastCampaign < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :user, optional: true
  has_many :broadcast_recipients, dependent: :destroy

  STATUSES = %w[draft running paused completed cancelled].freeze
  TIME_ZONE = 'America/Sao_Paulo'

  validates :title, presence: true
  validates :message_template, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :min_interval, :max_interval, numericality: { greater_than_or_equal_to: 30 }
  validates :daily_cap, numericality: { greater_than_or_equal_to: 1 }
  validate :interval_range

  scope :active, -> { where(status: 'running') }
  scope :ordered, -> { order(created_at: :desc) }

  def start!
    return false unless %w[draft paused].include?(status)

    update!(status: 'running', started_at: started_at || Time.current)
    true
  end

  def pause!
    update!(status: 'paused') if status == 'running'
  end

  def cancel!
    update!(status: 'cancelled') unless %w[completed cancelled].include?(status)
  end

  def next_pending_recipient
    broadcast_recipients.where(status: 'pending').order(:position, :id).first
  end

  def within_send_window?(time = Time.current)
    hour = time.in_time_zone(TIME_ZONE).hour
    if send_window_start <= send_window_end
      hour >= send_window_start && hour < send_window_end
    else
      hour >= send_window_start || hour < send_window_end
    end
  end

  def daily_cap_reached?(today = Date.current)
    sent_today_on == today && sent_today >= daily_cap
  end

  def register_send!(today = Date.current)
    if sent_today_on == today
      increment!(:sent_today)
    else
      update!(sent_today_on: today, sent_today: 1)
    end
  end

  def random_interval
    rand(min_interval..max_interval)
  end

  def recompute_counts!
    update!(
      total_count: broadcast_recipients.count,
      sent_count: broadcast_recipients.where(status: 'sent').count,
      failed_count: broadcast_recipients.where(status: 'failed').count
    )
  end

  def maybe_complete!
    return unless status == 'running'
    return if broadcast_recipients.where(status: 'pending').exists?

    update!(status: 'completed', completed_at: Time.current)
  end

  private

  def interval_range
    return if min_interval.blank? || max_interval.blank?

    errors.add(:max_interval, 'deve ser maior ou igual ao intervalo mínimo') if max_interval < min_interval
  end
end
