<template>
  <div class="crm-permissions">
    <header class="crm-permissions__header">
      <h2>Permissões do CRM</h2>
      <p>Gerencie quem pode acessar e modificar o CRM</p>
    </header>

    <div v-if="isLoading" class="crm-permissions__loading">
      <spinner />
      <span>Carregando permissões...</span>
    </div>

    <div v-else class="crm-permissions__content">
      <!-- Tabela de usuários -->
      <table class="crm-permissions__table">
        <thead>
          <tr>
            <th>Usuário</th>
            <th>Role</th>
            <th class="text-center">Visualizar</th>
            <th class="text-center">Editar</th>
            <th class="text-center">Excluir</th>
            <th class="text-center">Gerenciar</th>
            <th class="text-center">Exportar</th>
            <th>Visibilidade</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.user_id" :class="{ 'is-admin': user.is_admin }">
            <td>
              <div class="user-info">
                <img 
                  v-if="user.user_avatar" 
                  :src="user.user_avatar" 
                  :alt="user.user_name"
                  class="user-avatar"
                />
                <div v-else class="user-avatar user-avatar--initials">
                  {{ getInitials(user.user_name) }}
                </div>
                <div>
                  <div class="user-name">{{ user.user_name }}</div>
                  <div class="user-email">{{ user.user_email }}</div>
                </div>
              </div>
            </td>
            <td>
              <span class="role-badge" :class="`role-badge--${user.role}`">
                {{ user.role === 'administrator' ? 'Admin' : 'Agente' }}
              </span>
            </td>
            <td class="text-center">
              <input 
                type="checkbox" 
                :checked="user.crm.permissions.read"
                :disabled="user.is_admin"
                @change="togglePermission(user, 'read', $event)"
              />
            </td>
            <td class="text-center">
              <input 
                type="checkbox" 
                :checked="user.crm.permissions.write"
                :disabled="user.is_admin"
                @change="togglePermission(user, 'write', $event)"
              />
            </td>
            <td class="text-center">
              <input 
                type="checkbox" 
                :checked="user.crm.permissions.delete"
                :disabled="user.is_admin"
                @change="togglePermission(user, 'delete', $event)"
              />
            </td>
            <td class="text-center">
              <input 
                type="checkbox" 
                :checked="user.crm.permissions.manage"
                :disabled="user.is_admin"
                @change="togglePermission(user, 'manage', $event)"
              />
            </td>
            <td class="text-center">
              <input 
                type="checkbox" 
                :checked="user.crm.permissions.export"
                :disabled="user.is_admin"
                @change="togglePermission(user, 'export', $event)"
              />
            </td>
            <td>
              <select 
                :value="user.crm.visibility"
                :disabled="user.is_admin"
                class="visibility-select"
                @change="changeVisibility(user, $event)"
              >
                <option value="all">Todos os cards</option>
                <option value="team">Cards do time</option>
                <option value="own">Apenas próprios</option>
              </select>
            </td>
            <td>
              <span v-if="user.is_admin" class="admin-badge">
                Acesso total
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Legenda -->
      <div class="crm-permissions__legend">
        <h4>Legenda das permissões:</h4>
        <ul>
          <li><strong>Visualizar:</strong> Pode ver o board, cards e dashboard</li>
          <li><strong>Editar:</strong> Pode criar/editar cards, mover entre estágios, marcar ganho/perdido</li>
          <li><strong>Excluir:</strong> Pode remover cards do CRM</li>
          <li><strong>Gerenciar:</strong> Pode criar/editar pipelines, estágios, campos personalizados e automações</li>
          <li><strong>Exportar:</strong> Pode exportar dados do CRM</li>
        </ul>
        <h4>Níveis de visibilidade:</h4>
        <ul>
          <li><strong>Todos os cards:</strong> Vê todos os cards da conta</li>
          <li><strong>Cards do time:</strong> Vê apenas cards dos membros do seu time</li>
          <li><strong>Apenas próprios:</strong> Vê apenas cards atribuídos a ele</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'CrmPermissionsManager',
  components: {
    Spinner,
  },
  data() {
    return {
      users: [],
      isLoading: false,
      isSaving: false,
    };
  },
  computed: {
    accountId() {
      return this.$route.params.accountId;
    },
  },
  mounted() {
    this.loadPermissions();
  },
  methods: {
    async loadPermissions() {
      this.isLoading = true;
      try {
        const response = await KanbanAPI.getAllPermissions(this.accountId);
        this.users = response.data.users;
      } catch (error) {
        console.error('Erro ao carregar permissões:', error);
        this.$toast.error('Erro ao carregar permissões');
      } finally {
        this.isLoading = false;
      }
    },

    async togglePermission(user, permission, event) {
      const newValue = event.target.checked;
      const updatedPermissions = { ...user.crm.permissions, [permission]: newValue };

      try {
        await KanbanAPI.updateUserPermissions(this.accountId, user.user_id, {
          permissions: updatedPermissions,
        });

        // Atualiza localmente
        user.crm.permissions[permission] = newValue;
        this.$toast.success('Permissão atualizada');
      } catch (error) {
        console.error('Erro ao atualizar permissão:', error);
        this.$toast.error('Erro ao atualizar permissão');
        // Reverte o checkbox
        event.target.checked = !newValue;
      }
    },

    async changeVisibility(user, event) {
      const newVisibility = event.target.value;
      const oldVisibility = user.crm.visibility;

      try {
        await KanbanAPI.updateUserPermissions(this.accountId, user.user_id, {
          visibility: newVisibility,
        });

        // Atualiza localmente
        user.crm.visibility = newVisibility;
        this.$toast.success('Visibilidade atualizada');
      } catch (error) {
        console.error('Erro ao atualizar visibilidade:', error);
        this.$toast.error('Erro ao atualizar visibilidade');
        // Reverte o select
        event.target.value = oldVisibility;
      }
    },

    getInitials(name) {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .substring(0, 2)
        .toUpperCase();
    },
  },
};
</script>

<style lang="scss" scoped>
.crm-permissions {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;

  &__header {
    margin-bottom: 24px;

    h2 {
      font-size: 20px;
      font-weight: 600;
      color: var(--s-800);
      margin: 0 0 8px 0;
    }

    p {
      font-size: 14px;
      color: var(--s-500);
      margin: 0;
    }
  }

  &__loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 48px;
    gap: 16px;
    color: var(--s-500);
  }

  &__table {
    width: 100%;
    border-collapse: collapse;
    background: var(--white);
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

    th, td {
      padding: 12px 16px;
      text-align: left;
      border-bottom: 1px solid var(--s-100);
    }

    th {
      background: var(--s-50);
      font-size: 12px;
      font-weight: 600;
      color: var(--s-600);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    td {
      font-size: 14px;
      color: var(--s-700);
    }

    tr.is-admin {
      background: linear-gradient(90deg, rgba(139, 92, 246, 0.05) 0%, transparent 100%);
    }

    .text-center {
      text-align: center;
    }
  }

  &__legend {
    margin-top: 24px;
    padding: 16px;
    background: var(--s-50);
    border-radius: 8px;

    h4 {
      font-size: 13px;
      font-weight: 600;
      color: var(--s-700);
      margin: 0 0 8px 0;

      &:not(:first-child) {
        margin-top: 16px;
      }
    }

    ul {
      margin: 0;
      padding-left: 20px;
      font-size: 13px;
      color: var(--s-600);
      line-height: 1.6;
    }

    li {
      margin-bottom: 4px;
    }

    strong {
      color: var(--s-700);
    }
  }
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;

  &--initials {
    background: var(--w-500);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 600;
  }
}

.user-name {
  font-weight: 500;
  color: var(--s-800);
}

.user-email {
  font-size: 12px;
  color: var(--s-500);
}

.role-badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;

  &--administrator {
    background: rgba(139, 92, 246, 0.1);
    color: #7c3aed;
  }

  &--agent {
    background: rgba(59, 130, 246, 0.1);
    color: #2563eb;
  }
}

.admin-badge {
  font-size: 11px;
  color: var(--s-500);
  font-style: italic;
}

.visibility-select {
  padding: 6px 10px;
  border: 1px solid var(--s-200);
  border-radius: 4px;
  font-size: 13px;
  background: white;
  min-width: 140px;

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

/* Dark mode */
.dark {
  .crm-permissions {
    &__header {
      h2 { color: var(--s-100); }
      p { color: var(--s-400); }
    }

    &__table {
      background: var(--s-900);

      th {
        background: var(--s-800);
        color: var(--s-300);
      }

      td {
        color: var(--s-200);
        border-bottom-color: var(--s-700);
      }

      tr.is-admin {
        background: linear-gradient(90deg, rgba(139, 92, 246, 0.1) 0%, transparent 100%);
      }
    }

    &__legend {
      background: var(--s-800);

      h4 { color: var(--s-200); }
      ul { color: var(--s-400); }
      strong { color: var(--s-200); }
    }
  }

  .user-name { color: var(--s-100); }
  .user-email { color: var(--s-400); }

  .visibility-select {
    background: var(--s-800);
    border-color: var(--s-600);
    color: var(--s-200);
  }
}
</style>
