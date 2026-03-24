class ContractExpirationCheckJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    [30, 15, 7].each do |days|
      check_expiring_contracts(days)
    end
  end

  private

  def check_expiring_contracts(days)
    target_date = Date.current + days.days

    Contract.where(status: 'signed').where(plan_end_date: target_date).find_each do |contract|
      next unless contract.created_by.present?

      # Evitar notificações duplicadas
      existing = Notification.find_by(
        user: contract.created_by,
        account: contract.account,
        notification_type: :contract_expiring,
        primary_actor: contract,
        read_at: nil
      )
      next if existing.present?

      Notification.create!(
        account: contract.account,
        user: contract.created_by,
        notification_type: :contract_expiring,
        primary_actor: contract,
        meta: {
          message: "O contrato #{contract.contract_number} (#{contract.contractor_name}) expira em #{days} dias",
          days_until_expiry: days,
          contract_number: contract.contract_number,
          contractor_name: contract.contractor_name
        }
      )
    end
  end
end
