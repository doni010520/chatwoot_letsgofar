# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BaseController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user
  end
end