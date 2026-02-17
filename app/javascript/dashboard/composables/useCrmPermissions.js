// app/javascript/dashboard/composables/useCrmPermissions.js
//
// Composable para gerenciar permissões CRM no frontend.
// Fornece métodos reativos para verificar permissões do usuário atual.
//
// Uso:
//   import { useCrmPermissions } from 'dashboard/composables/useCrmPermissions';
//
//   const { canRead, canWrite, canManage, isLoading, loadPermissions } = useCrmPermissions();
//
//   // No template:
//   <button v-if="canWrite" @click="editCard">Editar</button>
//

import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

// Estado global compartilhado entre instâncias
const globalPermissions = ref(null);
const isLoading = ref(false);
const hasLoaded = ref(false);

export function useCrmPermissions() {
  const store = useStore();
  const currentRole = useMapGetter('getCurrentRole');
  const accountId = useMapGetter('getCurrentAccountId');

  // ==========================================
  // Computed - Permissões
  // ==========================================

  const isAdmin = computed(() => {
    return currentRole.value === 'administrator' || globalPermissions.value?.is_admin === true;
  });

  const canRead = computed(() => {
    if (isAdmin.value) return true;
    return globalPermissions.value?.permissions?.read === true;
  });

  const canWrite = computed(() => {
    if (isAdmin.value) return true;
    return globalPermissions.value?.permissions?.write === true;
  });

  const canDelete = computed(() => {
    if (isAdmin.value) return true;
    return globalPermissions.value?.permissions?.delete === true;
  });

  const canManage = computed(() => {
    if (isAdmin.value) return true;
    return globalPermissions.value?.permissions?.manage === true;
  });

  const canExport = computed(() => {
    if (isAdmin.value) return true;
    return globalPermissions.value?.permissions?.export === true;
  });

  const visibility = computed(() => {
    if (isAdmin.value) return 'all';
    return globalPermissions.value?.visibility || 'own';
  });

  const canSeeAllCards = computed(() => {
    return isAdmin.value || visibility.value === 'all';
  });

  const canSeeTeamCards = computed(() => {
    return isAdmin.value || visibility.value === 'all' || visibility.value === 'team';
  });

  // ==========================================
  // Métodos
  // ==========================================

  // Carrega permissões do backend
  const loadPermissions = async (forceReload = false) => {
    // Se já carregou e não é forçado, retorna
    if (hasLoaded.value && !forceReload) {
      return globalPermissions.value;
    }

    // Se já está carregando, aguarda
    if (isLoading.value) {
      return new Promise(resolve => {
        const check = setInterval(() => {
          if (!isLoading.value) {
            clearInterval(check);
            resolve(globalPermissions.value);
          }
        }, 100);
      });
    }

    isLoading.value = true;

    try {
      const response = await KanbanAPI.getCurrentPermissions(accountId.value);
      globalPermissions.value = response.data;
      hasLoaded.value = true;
      return response.data;
    } catch (error) {
      console.error('Erro ao carregar permissões CRM:', error);
      // Em caso de erro, assume permissões mínimas
      globalPermissions.value = {
        permissions: {
          read: true, // Mínimo para não bloquear totalmente
          write: false,
          delete: false,
          manage: false,
          export: false,
        },
        visibility: 'own',
        is_admin: false,
      };
      return globalPermissions.value;
    } finally {
      isLoading.value = false;
    }
  };

  // Recarrega permissões (útil após mudança de role)
  const refreshPermissions = () => {
    hasLoaded.value = false;
    return loadPermissions(true);
  };

  // Verifica se pode acessar um item específico
  const canAccessItem = (item) => {
    if (isAdmin.value || canSeeAllCards.value) return true;

    const currentUserId = store.getters.getCurrentUserID;

    if (canSeeTeamCards.value) {
      // Verifica se está no mesmo time (simplificado)
      // Na prática, você pode precisar de dados adicionais do time
      return item.assignee_id === currentUserId || item.assignee?.id === currentUserId;
    }

    // Visibilidade 'own': apenas itens atribuídos ao usuário
    return item.assignee_id === currentUserId || item.assignee?.id === currentUserId;
  };

  // Verifica se pode editar um item específico
  const canEditItem = (item) => {
    if (!canWrite.value) return false;
    return canAccessItem(item);
  };

  // Verifica se pode deletar um item específico
  const canDeleteItem = (item) => {
    if (!canDelete.value) return false;
    return canAccessItem(item);
  };

  // ==========================================
  // Lifecycle
  // ==========================================

  onMounted(() => {
    if (!hasLoaded.value) {
      loadPermissions();
    }
  });

  // ==========================================
  // Return
  // ==========================================

  return {
    // Estado
    permissions: globalPermissions,
    isLoading,
    hasLoaded,

    // Permissões básicas
    isAdmin,
    canRead,
    canWrite,
    canDelete,
    canManage,
    canExport,

    // Visibilidade
    visibility,
    canSeeAllCards,
    canSeeTeamCards,

    // Métodos
    loadPermissions,
    refreshPermissions,
    canAccessItem,
    canEditItem,
    canDeleteItem,
  };
}

// ==========================================
// Hook para uso em Options API
// ==========================================

export const crmPermissionsMixin = {
  data() {
    return {
      crmPermissions: null,
      crmPermissionsLoading: false,
    };
  },
  computed: {
    isCrmAdmin() {
      return this.$store.getters.getCurrentRole === 'administrator' || 
             this.crmPermissions?.is_admin === true;
    },
    canReadCrm() {
      return this.isCrmAdmin || this.crmPermissions?.permissions?.read === true;
    },
    canWriteCrm() {
      return this.isCrmAdmin || this.crmPermissions?.permissions?.write === true;
    },
    canDeleteCrm() {
      return this.isCrmAdmin || this.crmPermissions?.permissions?.delete === true;
    },
    canManageCrm() {
      return this.isCrmAdmin || this.crmPermissions?.permissions?.manage === true;
    },
    canExportCrm() {
      return this.isCrmAdmin || this.crmPermissions?.permissions?.export === true;
    },
  },
  methods: {
    async loadCrmPermissions() {
      this.crmPermissionsLoading = true;
      try {
        const response = await KanbanAPI.getCurrentPermissions(this.$route.params.accountId);
        this.crmPermissions = response.data;
      } catch (error) {
        console.error('Erro ao carregar permissões CRM:', error);
      } finally {
        this.crmPermissionsLoading = false;
      }
    },
  },
  mounted() {
    this.loadCrmPermissions();
  },
};

export default useCrmPermissions;
