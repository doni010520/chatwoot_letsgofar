# frozen_string_literal: true

# Envia UMA mensagem do disparo e se reagenda para a próxima, com intervalo
# aleatório (5-6 min por padrão), respeitando janela de horário e teto diário.
# Auto-reagendamento dá o espaçamento natural e é robusto a restart do worker.
class Broadcast::DispatchJob < ApplicationJob
  queue_as :low

  def perform(campaign_id)
    campaign = BroadcastCampaign.find_by(id: campaign_id)
    return unless campaign&.status == 'running'

    return reschedule(campaign, seconds_until_window_start(campaign)) unless campaign.within_send_window?
    return reschedule(campaign, seconds_until_window_start(campaign, next_day: true)) if campaign.daily_cap_reached?

    recipient = campaign.next_pending_recipient
    return campaign.maybe_complete! if recipient.nil?

    deliver(campaign, recipient)
    campaign.recompute_counts!

    if campaign.reload.status == 'running' && campaign.next_pending_recipient
      reschedule(campaign, campaign.random_interval)
    else
      campaign.maybe_complete!
    end
  end

  private

  def deliver(campaign, recipient)
    Broadcast::SendMessageService.new(campaign: campaign, recipient: recipient).call
    campaign.register_send!
  rescue StandardError => e
    Rails.logger.error("[Broadcast] falha ao enviar recipient #{recipient.id}: #{e.message}")
    recipient.mark_failed!(e.message)
  end

  def reschedule(campaign, seconds)
    seconds = [seconds.to_i, 5].max
    campaign.update_column(:next_run_at, Time.current + seconds) # rubocop:disable Rails/SkipsModelValidations
    self.class.set(wait: seconds.seconds).perform_later(campaign.id)
  end

  def seconds_until_window_start(campaign, next_day: false)
    now = Time.current.in_time_zone(BroadcastCampaign::TIME_ZONE)
    target = now.change(hour: campaign.send_window_start, min: 0, sec: 0)
    target += 1.day if next_day || now >= target
    (target - now).to_i
  end
end
