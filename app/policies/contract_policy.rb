class ContractPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    @account_user.administrator?
  end

  def send_for_signature?
    true
  end

  def cancel?
    true
  end

  def duplicate?
    true
  end

  def download_pdf?
    true
  end

  def resend_to_signer?
    true
  end

  def stats?
    true
  end

  def expiring?
    true
  end
end
