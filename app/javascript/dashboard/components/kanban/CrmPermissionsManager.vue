<template>
  <div class="crm-permissions">
    <p class="crm-permissions__subtitle">Gerencie quem pode acessar e modificar o CRM</p>

    <div v-if="isLoading" class="crm-permissions__loading">
      <spinner />
      <span>Carregando permissões...</span>
    </div>

    <div v-else class="crm-permissions__content">
      <!-- Tabela de usuários -->
      <div class="table-wrapper">
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
                  {{ user.role === 'administrator' ? 'ADMIN' : 'AGENTE' }}
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
                  <option value="all">Todos</option>
                  <option value="team">Time</option>
                  <option value="own">Próprios</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Legenda -->
      <div class="crm-permissions__legend">
        <div class="legend-column">
          <h4>Permissões:</h4>
          <ul>
            <li><strong>Visualizar:</strong> Ver board e dashboard</li>
            <li><strong>Editar:</strong> Criar/editar cards</li>
            <li><strong>Excluir:</strong> Remover cards</li>
            <li><strong>Gerenciar:</strong> Criar pipelines/campos</li>
            <li><strong>Exportar:</strong> Exportar dados</li>
          </ul>
        </div>
        <div class="legend-column">
          <h4>Visibilidade:</h4>
          <ul>
            <li><strong>Todos:</strong> Todos os cards</li>
            <li><strong>Time:</strong> Cards do time</li>
            <li><strong>Próprios:</strong> Apenas seus cards</li>
          </ul>
        </div>
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
  /* Removido padding para usar todo espaço do modal */
  
  &__subtitle {
    font-size: 13px;
    color: rgb(var(--slate-10));
    margin: 0 0 16px 0;
  }

  &__loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 48px;
    gap: 16px;
    color: rgb(var(--slate-10));
  }

  &__content {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .table-wrapper {
    overflow-x: auto;
    border-radius: 8px;
    border: 1px solid rgb(var(--slate-4));
  }

  &__table {
    width: 100%;
    border-collapse: collapse;
    background: rgb(var(--slate-1));
    font-size: 13px;

    th, td {
      padding: 10px 12px;
      text-align: left;
      border-bottom: 1px solid rgb(var(--slate-4));
      white-space: nowrap;
    }

    th {
      background: rgb(var(--slate-2));
      font-size: 11px;
      font-weight: 600;
      color: rgb(var(--slate-11));
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    td {
      color: rgb(var(--slate-12));
    }

    tbody tr:last-child td {
      border-bottom: none;
    }

    tr.is-admin {
      background: rgb(var(--iris-2));
    }

    .text-center {
      text-align: center;
    }

    input[type="checkbox"] {
      cursor: pointer;
      width: 16px;
      height: 16px;
    }

    input[type="checkbox"]:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  }

  &__legend {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    padding: 12px;
    background: rgb(var(--slate-2));
    border-radius: 8px;
    border: 1px solid rgb(var(--slate-4));

    h4 {
      font-size: 12px;
      font-weight: 600;
      color: rgb(var(--slate-12));
      margin: 0 0 8px 0;
    }

    ul {
      margin: 0;
      padding-left: 16px;
      font-size: 11px;
      color: rgb(var(--slate-11));
      line-height: 1.5;
    }

    li {
      margin-bottom: 4px;
    }

    strong {
      color: rgb(var(--slate-12));
    }
  }
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;

  &--initials {
    background: rgb(var(--blue-9));
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 600;
  }
}

.user-name {
  font-size: 13px;
  font-weight: 500;
  color: rgb(var(--slate-12));
  line-height: 1.3;
}

.user-email {
  font-size: 11px;
  color: rgb(var(--slate-10));
  line-height: 1.3;
}

.role-badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;

  &--administrator {
    background: rgb(var(--iris-3));
    color: rgb(var(--iris-11));
  }

  &--agent {
    background: rgb(var(--slate-3));
    color: rgb(var(--slate-11));
  }
}

.visibility-select {
  padding: 4px 8px;
  font-size: 12px;
  background: rgb(var(--slate-1));
  border: 1px solid rgb(var(--slate-4));
  border-radius: 4px;
  color: rgb(var(--slate-12));
  cursor: pointer;
  min-width: 100px;

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  &:focus {
    outline: none;
    border-color: rgb(var(--blue-9));
  }
}

.admin-badge {
  font-size: 11px;
  color: rgb(var(--iris-11));
  font-weight: 500;
}
</style>
