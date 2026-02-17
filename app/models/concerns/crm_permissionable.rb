# frozen_string_literal: true

# app/models/concerns/crm_permissionable.rb
#
# Este concern adiciona funcionalidades de permissão CRM ao AccountUser.
# Usa bit flags para armazenar múltiplas permissões em um único integer.
#
# Permissões disponíveis:
#   - crm_read:    Visualizar board, cards e dashboard
#   - crm_write:   Criar/editar cards, mover entre estágios, marcar ganho/perdido
#   - crm_delete:  Remover cards do CRM
#   - crm_manage:  Gerenciar pipelines, estágios, campos personalizados, automações
#   - crm_export:  Exportar dados do CRM
#
# Níveis de visibilidade:
#   - all:  Vê todos os cards da conta
#   - team: Vê apenas cards do seu time
#   - own:  Vê apenas cards atribuídos a ele
#
# Uso:
#   account_user.can_read_crm?
#   account_user.can_manage_crm?
#   account_user.grant_crm_permission!(:write)
#   account_user.revoke_crm_permission!(:manage)
#   account_user.crm_visibility_scope
#

module CrmPermissionable
  extend ActiveSupport::Concern

  # Bit flags para permissões CRM
  CRM_PERMISSIONS = {
    read:   1 << 0,  # 1  - Visualizar
    write:  1 << 1,  # 2  - Criar/editar
    delete: 1 << 2,  # 4  - Remover
    manage: 1 << 3,  # 8  - Gerenciar configurações
    export: 1 << 4   # 16 - Exportar dados
  }.freeze

  # Níveis de visibilidade
  CRM_VISIBILITY_LEVELS = {
    all:  0,  # Vê todos os cards
    team: 1,  # Vê cards do time
    own:  2   # Vê apenas próprios cards
  }.freeze

  # Permissões padrão por role
  DEFAULT_PERMISSIONS = {
    administrator: [:read, :write, :delete, :manage, :export],
    agent: [:read, :write]
  }.freeze

  # Visibilidade padrão por role
  DEFAULT_VISIBILITY = {
    administrator: :all,
    agent: :own
  }.freeze

  included do
    # Callbacks
    after_initialize :set_default_crm_permissions, if: :new_record?

    # Enum para visibilidade (mais legível)
    enum crm_visibility: CRM_VISIBILITY_LEVELS, _prefix: :crm_visibility
  end

  # ==========================================
  # Métodos de verificação de permissão
  # ==========================================

  def can_read_crm?
    administrator? || has_crm_permission?(:read)
  end

  def can_write_crm?
    administrator? || has_crm_permission?(:write)
  end

  def can_delete_crm?
    administrator? || has_crm_permission?(:delete)
  end

  def can_manage_crm?
    administrator? || has_crm_permission?(:manage)
  end

  def can_export_crm?
    administrator? || has_crm_permission?(:export)
  end

  # Verifica se tem uma permissão específica
  def has_crm_permission?(permission)
    return true if administrator?

    flag = CRM_PERMISSIONS[permission.to_sym]
    return false unless flag

    (crm_permissions & flag) != 0
  end

  # Retorna array de permissões ativas
  def crm_permissions_list
    return CRM_PERMISSIONS.keys if administrator?

    CRM_PERMISSIONS.select { |perm, flag| (crm_permissions & flag) != 0 }.keys
  end

  # ==========================================
  # Métodos de modificação de permissão
  # ==========================================

  # Concede uma permissão
  def grant_crm_permission!(permission)
    flag = CRM_PERMISSIONS[permission.to_sym]
    return false unless flag

    update!(crm_permissions: crm_permissions | flag)
  end

  # Revoga uma permissão
  def revoke_crm_permission!(permission)
    flag = CRM_PERMISSIONS[permission.to_sym]
    return false unless flag

    update!(crm_permissions: crm_permissions & ~flag)
  end

  # Define múltiplas permissões de uma vez
  def set_crm_permissions!(permissions_array)
    new_value = permissions_array.sum { |p| CRM_PERMISSIONS[p.to_sym] || 0 }
    update!(crm_permissions: new_value)
  end

  # Reseta para permissões padrão do role
  def reset_crm_permissions!
    set_default_crm_permissions
    save!
  end

  # ==========================================
  # Métodos de visibilidade
  # ==========================================

  # Retorna o escopo de visibilidade para queries
  def crm_visibility_scope(base_scope)
    return base_scope if administrator? || crm_visibility_all?

    if crm_visibility_team?
      # Filtra por times do usuário
      team_ids = user.team_ids
      if team_ids.any?
        base_scope.joins(:assignee)
                  .joins('LEFT JOIN team_members ON team_members.user_id = conversations.assignee_id')
                  .where('team_members.team_id IN (?) OR conversations.assignee_id = ?', team_ids, user.id)
      else
        # Se não tem time, mostra apenas os próprios
        base_scope.where(assignee_id: user.id)
      end
    else
      # Visibilidade own: apenas cards atribuídos ao usuário
      base_scope.where(assignee_id: user.id)
    end
  end

  # Define visibilidade
  def set_crm_visibility!(level)
    update!(crm_visibility: CRM_VISIBILITY_LEVELS[level.to_sym])
  end

  # ==========================================
  # Métodos auxiliares
  # ==========================================

  # Retorna hash de permissões para API
  def crm_permissions_hash
    {
      permissions: {
        read: can_read_crm?,
        write: can_write_crm?,
        delete: can_delete_crm?,
        manage: can_manage_crm?,
        export: can_export_crm?
      },
      visibility: crm_visibility,
      is_admin: administrator?
    }
  end

  private

  def set_default_crm_permissions
    return if crm_permissions.present? && crm_permissions > 0

    role_key = role&.to_sym || :agent
    default_perms = DEFAULT_PERMISSIONS[role_key] || DEFAULT_PERMISSIONS[:agent]
    default_vis = DEFAULT_VISIBILITY[role_key] || DEFAULT_VISIBILITY[:agent]

    self.crm_permissions = default_perms.sum { |p| CRM_PERMISSIONS[p] }
    self.crm_visibility = CRM_VISIBILITY_LEVELS[default_vis]
  end
end
