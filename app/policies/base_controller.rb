# frozen_string_literal: true

# app/controllers/api/v1/accounts/kanban/base_controller.rb
#
# Controller base para todos os controllers do módulo CRM/Kanban.
# Fornece métodos de autorização e helpers comuns.
#

module Api
  module V1
    module Accounts
      module Kanban
        class BaseController < Api::V1::Accounts::BaseController
          before_action :authorize_crm_access

          private

          # ==========================================
          # Métodos de autorização
          # ==========================================

          def authorize_crm_access
            authorize :kanban, :index?
          end

          def authorize_crm_read
            authorize :kanban, :show?
          end

          def authorize_crm_write
            authorize :kanban, :update?
          end

          def authorize_crm_delete
            authorize :kanban, :destroy?
          end

          def authorize_crm_manage
            authorize :kanban, :manage_pipeline?
          end

          def authorize_crm_export
            authorize :kanban, :export?
          end

          # ==========================================
          # Helpers de permissão
          # ==========================================

          def current_account_user
            @current_account_user ||= Current.account_user
          end

          def can_read_crm?
            current_account_user&.can_read_crm?
          end

          def can_write_crm?
            current_account_user&.can_write_crm?
          end

          def can_delete_crm?
            current_account_user&.can_delete_crm?
          end

          def can_manage_crm?
            current_account_user&.can_manage_crm?
          end

          def can_export_crm?
            current_account_user&.can_export_crm?
          end

          # Retorna permissões do usuário atual para incluir na response
          def crm_permissions_for_response
            current_account_user&.crm_permissions_hash || {
              permissions: {
                read: false,
                write: false,
                delete: false,
                manage: false,
                export: false
              },
              visibility: 'own',
              is_admin: false
            }
          end

          # ==========================================
          # Filtro de visibilidade
          # ==========================================

          # Aplica filtro de visibilidade baseado nas permissões do usuário
          def apply_visibility_scope(scope)
            return scope if current_account_user&.administrator?

            current_account_user&.crm_visibility_scope(scope) || scope.none
          end

          # ==========================================
          # Verificação de ownership
          # ==========================================

          # Verifica se o usuário pode acessar um item específico
          def can_access_item?(item)
            return true if current_account_user&.administrator?
            return true if current_account_user&.crm_visibility_all?

            if current_account_user&.crm_visibility_team?
              # Verifica se está no mesmo time
              team_ids = current_account_user.user.team_ids
              item_assignee_teams = item.assignee&.team_ids || []
              return true if (team_ids & item_assignee_teams).any?
              return item.assignee_id == current_account_user.user_id
            end

            # Visibilidade own: apenas se for assignee
            item.assignee_id == current_account_user.user_id
          end

          # Verifica acesso e retorna 403 se não autorizado
          def authorize_item_access!(item)
            return if can_access_item?(item)

            render json: { error: 'Você não tem permissão para acessar este item' }, status: :forbidden
          end

          # ==========================================
          # Error handling
          # ==========================================

          def handle_authorization_error
            render json: {
              error: 'Acesso negado',
              message: 'Você não tem permissão para realizar esta ação no CRM'
            }, status: :forbidden
          end
        end
      end
    end
  end
end
