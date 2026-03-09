# frozen_string_literal: true

class AgentTaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    can_access_task?
  end

  def create?
    true
  end

  def update?
    can_modify_task?
  end

  def destroy?
    can_modify_task?
  end

  def complete?
    can_modify_task?
  end

  def start?
    can_modify_task?
  end

  def cancel?
    can_modify_task?
  end

  def reopen?
    can_modify_task?
  end

  def assign?
    can_modify_task?
  end

  def calendar?
    true
  end

  def stats?
    true
  end

  def kanban?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end

  private

  def can_access_task?
    return true if user.administrator?
    return true if record.assigned_to_id == user.id
    return true if record.created_by_id == user.id

    false
  end

  def can_modify_task?
    return true if user.administrator?
    return true if record.assigned_to_id == user.id
    return true if record.created_by_id == user.id

    false
  end
end
