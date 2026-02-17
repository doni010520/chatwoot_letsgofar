# frozen_string_literal: true

# app/policies/kanban_policy.rb
#
# Policy de autorização para o módulo CRM/Kanban.
# Usa Pundit para verificar permissões de acesso.
#
# Uso nos controllers:
#   authorize :kanban, :index?
#   authorize @pipeline, :manage?
#

class KanbanPolicy < ApplicationPolicy
  # ==========================================
  # Ações de visualização
  # ==========================================

  # Pode ver o board/lista de pipelines?
  def index?
    crm_permission?(:read)
  end

  # Pode ver um pipeline específico?
  def show?
    crm_permission?(:read)
  end

  # Pode ver o dashboard?
  def dashboard?
    crm_permission?(:read)
  end

  # ==========================================
  # Ações de escrita
  # ==========================================

  # Pode criar novos items no board?
  def create?
    crm_permission?(:write)
  end

  # Pode atualizar items (mover cards, editar valores)?
  def update?
    crm_permission?(:write)
  end

  # Pode mover cards entre estágios?
  def move?
    crm_permission?(:write)
  end

  # Pode marcar como ganho/perdido?
  def close?
    crm_permission?(:write)
  end

  # ==========================================
  # Ações de exclusão
  # ==========================================

  # Pode remover items do board?
  def destroy?
    crm_permission?(:delete)
  end

  # Pode remover card do CRM?
  def remove_from_crm?
    crm_permission?(:delete)
  end

  # ==========================================
  # Ações de gerenciamento
  # ==========================================

  # Pode gerenciar pipelines (criar, editar, excluir)?
  def manage_pipeline?
    crm_permission?(:manage)
  end

  # Pode gerenciar estágios?
  def manage_stages?
    crm_permission?(:manage)
  end

  # Pode gerenciar campos personalizados?
  def manage_custom_fields?
    crm_permission?(:manage)
  end

  # Pode gerenciar automações?
  def manage_automations?
    crm_permission?(:manage)
  end

  # Pode configurar o CRM?
  def settings?
    crm_permission?(:manage)
  end

  # ==========================================
  # Ações de exportação
  # ==========================================

  # Pode exportar dados?
  def export?
    crm_permission?(:export)
  end

  # Pode importar dados?
  def import?
    crm_permission?(:manage)
  end

  # ==========================================
  # Scope para listagem
  # ==========================================

  class Scope < Scope
    def resolve
      return scope.none unless account_user&.can_read_crm?

      # Aplica filtro de visibilidade
      account_user.crm_visibility_scope(scope.where(account_id: account.id))
    end
  end

  private

  # Verifica se o usuário tem a permissão CRM especificada
  def crm_permission?(permission)
    return false unless account_user

    case permission
    when :read
      account_user.can_read_crm?
    when :write
      account_user.can_write_crm?
    when :delete
      account_user.can_delete_crm?
    when :manage
      account_user.can_manage_crm?
    when :export
      account_user.can_export_crm?
    else
      false
    end
  end
end
