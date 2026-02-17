# frozen_string_literal: true

# app/controllers/api/v1/accounts/kanban/base_controller.rb
#
# Controller base para todos os controllers do módulo CRM/Kanban.
# Fornece métodos de autorização e helpers comuns.
#

class Api::V1::Accounts::Kanban::BaseController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :authorize_crm_access

  private

  # ==========================================
  # Verificação básica de autenticação
  # ==========================================

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user
  end

  # ==========================================
  # Métodos de autorização CRM
  # ==========================================

  def authorize_crm_access
    return if can_read_crm?

    render json: { error: 'Você não tem permissão para acessar o CRM' }, status: :forbidden
  end

  def authorize_crm_write
    return if can_write_crm?

    render json: { error: 'Você não tem permissão para editar no CRM' }, status: :forbidden
  end

  def authorize_crm_delete
    return if can_delete_crm?

    render json: { error: 'Você não tem permissão para excluir do CRM' }, status: :forbidden
  end

  def authorize_crm_manage
    return if can_manage_crm?

    render json: { error: 'Você não tem permissão para gerenciar o CRM' }, status: :forbidden
  end

  def authorize_crm_export
    return if can_export_crm?

    render json: { error: 'Você não tem permissão para exportar dados do CRM' }, status: :forbidden
  end

  # ==========================================
  # Helpers de permissão
  # ==========================================

  def current_account_user
    @current_account_user ||= Current.account_user
  end

  def can_read_crm?
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:can_read_crm?)

    current_account_user.can_read_crm?
  end

  def can_write_crm?
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:can_write_crm?)

    current_account_user.can_write_crm?
  end

  def can_delete_crm?
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:can_delete_crm?)

    current_account_user.can_delete_crm?
  end

  def can_manage_crm?
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:can_manage_crm?)

    current_account_user.can_manage_crm?
  end

  def can_export_crm?
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:can_export_crm?)

    current_account_user.can_export_crm?
  end

  # Retorna permissões do usuário atual para incluir na response
  def crm_permissions_for_response
    return admin_permissions if current_account_user&.administrator?
    return default_permissions unless current_account_user.respond_to?(:crm_permissions_hash)

    current_account_user.crm_permissions_hash
  end

  # ==========================================
  # Filtro de visibilidade
  # ==========================================

  # Aplica filtro de visibilidade baseado nas permissões do usuário
  def apply_visibility_scope(scope)
    return scope if current_account_user&.administrator?
    return scope unless current_account_user.respond_to?(:crm_visibility_scope)

    current_account_user.crm_visibility_scope(scope)
  end

  # ==========================================
  # Verificação de ownership
  # ==========================================

  # Verifica se o usuário pode acessar um item específico
  def can_access_item?(item)
    return true if current_account_user&.administrator?
    return true unless current_account_user.respond_to?(:crm_visibility)

    visibility = current_account_user.crm_visibility

    case visibility
    when 'all', 0
      true
    when 'team', 1
      # Verifica se está no mesmo time
      team_ids = current_account_user.user.team_ids
      item_assignee_teams = item.assignee&.team_ids || []
      return true if (team_ids & item_assignee_teams).any?

      item.assignee_id == current_account_user.user_id
    else
      # Visibilidade own: apenas se for assignee
      item.assignee_id == current_account_user.user_id
    end
  end

  # Verifica acesso e retorna 403 se não autorizado
  def authorize_item_access!(item)
    return if can_access_item?(item)

    render json: { error: 'Você não tem permissão para acessar este item' }, status: :forbidden
  end

  private

  def admin_permissions
    {
      permissions: {
        read: true,
        write: true,
        delete: true,
        manage: true,
        export: true
      },
      visibility: 'all',
      is_admin: true
    }
  end

  def default_permissions
    {
      permissions: {
        read: true,
        write: true,
        delete: false,
        manage: false,
        export: false
      },
      visibility: 'own',
      is_admin: false
    }
  end
end
