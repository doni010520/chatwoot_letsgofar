# frozen_string_literal: true

# app/controllers/api/v1/accounts/kanban/permissions_controller.rb
#
# Controller para gerenciar permissões CRM dos usuários.
# Apenas administradores podem modificar permissões.
#
# Endpoints:
#   GET    /api/v1/accounts/:account_id/kanban/permissions          - Lista permissões de todos os usuários
#   GET    /api/v1/accounts/:account_id/kanban/permissions/:user_id - Mostra permissões de um usuário
#   PUT    /api/v1/accounts/:account_id/kanban/permissions/:user_id - Atualiza permissões de um usuário
#   GET    /api/v1/accounts/:account_id/kanban/permissions/current  - Retorna permissões do usuário atual
#

module Api
  module V1
    module Accounts
      module Kanban
        class PermissionsController < Api::V1::Accounts::BaseController
          before_action :authorize_admin, except: [:current]
          before_action :set_target_account_user, only: [:show, :update]

          # GET /api/v1/accounts/:account_id/kanban/permissions
          # Lista permissões CRM de todos os usuários da conta
          def index
            @account_users = Current.account.account_users
                                    .includes(:user)
                                    .order('users.name ASC')

            render json: {
              users: @account_users.map { |au| user_permissions_json(au) }
            }
          end

          # GET /api/v1/accounts/:account_id/kanban/permissions/:user_id
          # Mostra permissões CRM de um usuário específico
          def show
            render json: user_permissions_json(@target_account_user)
          end

          # PUT /api/v1/accounts/:account_id/kanban/permissions/:user_id
          # Atualiza permissões CRM de um usuário
          def update
            # Não permite editar permissões de outros admins (exceto super admin)
            if @target_account_user.administrator? && @target_account_user.id != Current.account_user.id
              return render json: { error: 'Não é possível modificar permissões de outro administrador' }, status: :forbidden
            end

            if update_permissions
              render json: {
                message: 'Permissões atualizadas com sucesso',
                user: user_permissions_json(@target_account_user)
              }
            else
              render json: { error: 'Erro ao atualizar permissões' }, status: :unprocessable_entity
            end
          end

          # GET /api/v1/accounts/:account_id/kanban/permissions/current
          # Retorna permissões do usuário atual (não requer admin)
          def current
            render json: current_user_permissions
          end

          private

          def authorize_admin
            return if Current.account_user&.administrator?

            render json: { error: 'Apenas administradores podem gerenciar permissões' }, status: :forbidden
          end

          def set_target_account_user
            @target_account_user = Current.account.account_users.find_by!(user_id: params[:user_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Usuário não encontrado' }, status: :not_found
          end

          def update_permissions
            ActiveRecord::Base.transaction do
              # Atualiza permissões se fornecidas
              if params[:permissions].present?
                permissions_array = params[:permissions].select { |_k, v| v == true || v == 'true' }.keys.map(&:to_sym)
                @target_account_user.set_crm_permissions!(permissions_array)
              end

              # Atualiza visibilidade se fornecida
              if params[:visibility].present?
                @target_account_user.set_crm_visibility!(params[:visibility])
              end

              true
            end
          rescue StandardError => e
            Rails.logger.error "Erro ao atualizar permissões CRM: #{e.message}"
            false
          end

          def user_permissions_json(account_user)
            # Verifica se o concern está disponível
            if account_user.respond_to?(:crm_permissions_hash)
              {
                user_id: account_user.user_id,
                user_name: account_user.user.name,
                user_email: account_user.user.email,
                user_avatar: account_user.user.avatar_url,
                role: account_user.role,
                is_admin: account_user.administrator?,
                crm: account_user.crm_permissions_hash
              }
            else
              # Fallback se concern não estiver instalado
              {
                user_id: account_user.user_id,
                user_name: account_user.user.name,
                user_email: account_user.user.email,
                user_avatar: account_user.user.avatar_url,
                role: account_user.role,
                is_admin: account_user.administrator?,
                crm: default_permissions_for(account_user)
              }
            end
          end

          def current_user_permissions
            account_user = Current.account_user
            
            if account_user.respond_to?(:crm_permissions_hash)
              account_user.crm_permissions_hash
            else
              default_permissions_for(account_user)
            end
          end

          def default_permissions_for(account_user)
            if account_user.administrator?
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
            else
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
        end
      end
    end
  end
end
