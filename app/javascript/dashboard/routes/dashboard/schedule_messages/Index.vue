<template>
  <div class="scheduled-messages-view">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header__left">
        <h1 class="page-header__title">
          <svg class="page-header__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/>
            <line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
          Mensagens Agendadas
        </h1>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="list-toolbar">
      <div class="list-toolbar__left">
        <div class="list-toolbar__search">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar por contato ou mensagem..."
            @input="onSearchChange"
          />
        </div>
        <span class="list-toolbar__count">
          {{ filteredMessages.length }} de {{ messages.length }} mensagens
        </span>
      </div>
      <div class="list-toolbar__right">
        <CustomSelect
          v-model="filters.status"
          :options="[
            { value: '', label: 'Todos os status' },
            { value: 'pending', label: 'Pendentes' },
            { value: 'sent', label: 'Enviadas' },
            { value: 'failed', label: 'Falhadas' }
          ]"
          custom-class="list-toolbar__filter"
          @change="loadMessages"
        />
        <CustomSelect
          v-model="filters.sortBy"
          :options="[
            { value: 'date_asc', label: 'Mais próximas' },
            { value: 'date_desc', label: 'Mais distantes' },
            { value: 'contact', label: 'Contato (A-Z)' }
          ]"
          custom-class="list-toolbar__filter"
          @change="applySort"
        />
        <button v-if="hasFilters" class="list-toolbar__clear" @click="clearFilters">
          Limpar filtros
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-state">
      <div class="loading-spinner"></div>
      <span>Carregando mensagens...</span>
    </div>

    <!-- Table -->
    <div v-else class="list-table-container">
      <table class="list-table">
        <thead>
          <tr>
            <th class="list-table__th list-table__th--checkbox">
              <input
                type="checkbox"
                :checked="isAllSelected"
                :indeterminate="isIndeterminate"
                @change="toggleSelectAll"
              />
            </th>
            <th class="list-table__th list-table__th--sortable" @click="sortBy('contact')">
              <span>Contato</span>
              <span class="sort-icon" v-if="sortField === 'contact'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th list-table__th--sortable" @click="sortBy('scheduled_at')">
              <span>Envio Agendado</span>
              <span class="sort-icon" v-if="sortField === 'scheduled_at'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th">Status</th>
            <th class="list-table__th">Mensagem</th>
            <th class="list-table__th list-table__th--sortable" @click="sortBy('created_by')">
              <span>Agendado por</span>
              <span class="sort-icon" v-if="sortField === 'created_by'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th list-table__th--sortable" @click="sortBy('created_at')">
              <span>Criado em</span>
              <span class="sort-icon" v-if="sortField === 'created_at'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th list-table__th--actions">Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="msg in paginatedMessages"
            :key="msg.id"
            class="list-table__row"
            :class="{ 'list-table__row--selected': selectedIds.includes(msg.id) }"
            @click="viewMessage(msg)"
          >
            <td class="list-table__td list-table__td--checkbox" @click.stop>
              <input
                type="checkbox"
                :checked="selectedIds.includes(msg.id)"
                @change="toggleSelect(msg.id)"
              />
            </td>
            <td class="list-table__td list-table__td--name">
              <div class="contact-item">
                <img 
                  v-if="msg.contact.avatar" 
                  :src="msg.contact.avatar" 
                  :alt="msg.contact.name"
                  class="contact-avatar-img"
                />
                <div v-else class="contact-avatar" :style="{ backgroundColor: getAvatarColor(msg.contact.name) }">
                  {{ getInitials(msg.contact.name) }}
                </div>
                <div class="contact-info">
                  <span class="contact-info__name">{{ msg.contact.name || 'Sem nome' }}</span>
                  <span class="contact-info__phone">{{ msg.contact.phone || '-' }}</span>
                </div>
              </div>
            </td>
            <td class="list-table__td list-table__td--date">
              <div class="scheduled-date">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <polyline points="12 6 12 12 16 14"/>
                </svg>
                <span>{{ formatDateTime(msg.scheduled_at) }}</span>
              </div>
            </td>
            <td class="list-table__td">
              <span
                class="status-badge"
                :class="`status-badge--${msg.status}`"
              >
                {{ statusLabel(msg.status) }}
              </span>
            </td>
            <td class="list-table__td list-table__td--message">
              <span class="message-preview">{{ truncateMessage(msg.content) }}</span>
            </td>
            <td class="list-table__td list-table__td--user">
              <div class="user-info">
                <img 
                  v-if="getUserInfo(msg).avatar" 
                  :src="getUserInfo(msg).avatar" 
                  :alt="getUserInfo(msg).name"
                  class="user-avatar-img"
                />
                <div v-else class="user-avatar" :style="{ backgroundColor: getAvatarColor(getUserInfo(msg).name) }">
                  {{ getInitials(getUserInfo(msg).name) }}
                </div>
                <span class="user-name">{{ getUserInfo(msg).name }}</span>
              </div>
            </td>
            <td class="list-table__td list-table__td--date-small">
              {{ formatDateTime(msg.created_at) }}
            </td>
            <td class="list-table__td list-table__td--actions" @click.stop>
              <div class="actions-menu">
                <button class="action-btn action-btn--danger" title="Excluir" @click="deleteMessage(msg)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="paginatedMessages.length === 0">
            <td colspan="8" class="list-table__empty">
              <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <line x1="12" y1="8" x2="12" y2="12"/>
                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <span>Nenhuma mensagem agendada encontrada</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div class="list-pagination">
      <div class="list-pagination__info">
        Mostrando {{ startIndex + 1 }} - {{ endIndex }} de {{ filteredMessages.length }}
      </div>
      <div class="list-pagination__controls">
        <CustomSelect
          v-model="perPage"
          :options="[
            { value: 10, label: '10 por página' },
            { value: 25, label: '25 por página' },
            { value: 50, label: '50 por página' },
            { value: 100, label: '100 por página' }
          ]"
          custom-class="list-pagination__per-page"
          :open-upward="true"
          @change="currentPage = 1"
        />
        <div class="list-pagination__buttons">
          <button class="pagination-btn" :disabled="currentPage === 1" @click="currentPage = 1">««</button>
          <button class="pagination-btn" :disabled="currentPage === 1" @click="currentPage--">«</button>
          <span class="pagination-info">Página {{ currentPage }} de {{ totalPages }}</span>
          <button class="pagination-btn" :disabled="currentPage === totalPages" @click="currentPage++">»</button>
          <button class="pagination-btn" :disabled="currentPage === totalPages" @click="currentPage = totalPages">»»</button>
        </div>
      </div>
    </div>

    <!-- Modal de Visualização -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="closeViewModal">
      <div class="modal-content modal-content--view">
        <div class="modal-header">
          <h3>Detalhes do Agendamento</h3>
          <button class="modal-close" @click="closeViewModal">✕</button>
        </div>
        <div class="modal-body">
          <!-- Contato -->
          <div class="view-section">
            <h4 class="view-section__title">Contato</h4>
            <div class="contact-detail">
              <img 
                v-if="viewingMessage.contact?.avatar" 
                :src="viewingMessage.contact.avatar" 
                :alt="viewingMessage.contact.name"
                class="contact-detail__avatar"
              />
              <div v-else class="contact-detail__avatar contact-detail__avatar--initials" 
                   :style="{ backgroundColor: getAvatarColor(viewingMessage.contact?.name) }">
                {{ getInitials(viewingMessage.contact?.name) }}
              </div>
              <div class="contact-detail__info">
                <div class="contact-detail__name">{{ viewingMessage.contact?.name || 'Sem nome' }}</div>
                <div class="contact-detail__phone">{{ viewingMessage.contact?.phone || '-' }}</div>
              </div>
            </div>
          </div>

          <!-- Agendamento -->
          <div class="view-section">
            <h4 class="view-section__title">Envio Agendado Para</h4>
            <div class="view-info">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
              </svg>
              <span>{{ formatDateTime(viewingMessage.scheduled_at) }}</span>
            </div>
          </div>

          <!-- Status -->
          <div class="view-section">
            <h4 class="view-section__title">Status</h4>
            <span
              class="status-badge status-badge--large"
              :class="`status-badge--${viewingMessage.status}`"
            >
              {{ statusLabel(viewingMessage.status) }}
            </span>
          </div>

          <!-- Mensagem -->
          <div class="view-section">
            <h4 class="view-section__title">Mensagem</h4>
            <div class="message-full">{{ viewingMessage.content || '-' }}</div>
          </div>

          <!-- Informações de Criação -->
          <div class="view-section-grid">
            <div class="view-section">
              <h4 class="view-section__title">Agendado Por</h4>
              <div class="user-detail">
                <img 
                  v-if="getUserInfo(viewingMessage).avatar" 
                  :src="getUserInfo(viewingMessage).avatar" 
                  :alt="getUserInfo(viewingMessage).name"
                  class="user-detail__avatar"
                />
                <div v-else class="user-detail__avatar user-detail__avatar--initials"
                     :style="{ backgroundColor: getAvatarColor(getUserInfo(viewingMessage).name) }">
                  {{ getInitials(getUserInfo(viewingMessage).name) }}
                </div>
                <span class="user-detail__name">{{ getUserInfo(viewingMessage).name }}</span>
              </div>
            </div>

            <div class="view-section">
              <h4 class="view-section__title">Criado Em</h4>
              <div class="view-info">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                  <line x1="16" y1="2" x2="16" y2="6"/>
                  <line x1="8" y1="2" x2="8" y2="6"/>
                  <line x1="3" y1="10" x2="21" y2="10"/>
                </svg>
                <span>{{ formatDateTime(viewingMessage.created_at) }}</span>
              </div>
            </div>
          </div>

          <div class="modal-actions">
            <button class="btn-close" @click="closeViewModal">Fechar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { debounce } from '@chatwoot/utils';
import CustomSelect from '../../../components/ui/CustomSelect.vue';

export default {
  name: 'ScheduledMessages',
  components: {
    CustomSelect 
  },
  setup() {
    const store = useStore();
    
    // State
    const messages = ref([]);
    const loading = ref(false);
    const searchQuery = ref('');
    const selectedIds = ref([]);
    const currentPage = ref(1);
    const perPage = ref(25);
    const sortField = ref('scheduled_at');
    const sortDirection = ref('asc');
    const showViewModal = ref(false);
    const viewingMessage = ref({});
    
    const filters = ref({
      search: '',
      status: '',
      sortBy: 'date_asc'
    });

    // Computed
    const filteredMessages = computed(() => {
      let result = [...messages.value];

      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        result = result.filter(msg => 
          msg.contact?.name?.toLowerCase().includes(query) ||
          msg.contact?.phone?.includes(query) ||
          msg.content?.toLowerCase().includes(query)
        );
      }

      if (filters.value.status) {
        result = result.filter(msg => msg.status === filters.value.status);
      }

      result.sort((a, b) => {
        let aVal, bVal;
        
        switch (sortField.value) {
          case 'contact':
            aVal = a.contact?.name || '';
            bVal = b.contact?.name || '';
            break;
          case 'scheduled_at':
            aVal = new Date(a.scheduled_at);
            bVal = new Date(b.scheduled_at);
            break;
          case 'created_by':
            aVal = getUserInfo(a).name;
            bVal = getUserInfo(b).name;
            break;
          case 'created_at':
            aVal = new Date(a.created_at);
            bVal = new Date(b.created_at);
            break;
          default:
            return 0;
        }

        if (sortDirection.value === 'asc') {
          return aVal > bVal ? 1 : -1;
        } else {
          return aVal < bVal ? 1 : -1;
        }
      });

      return result;
    });

    const totalPages = computed(() => Math.ceil(filteredMessages.value.length / perPage.value));
    const startIndex = computed(() => (currentPage.value - 1) * perPage.value);
    const endIndex = computed(() => Math.min(startIndex.value + perPage.value, filteredMessages.value.length));
    
    const paginatedMessages = computed(() => {
      return filteredMessages.value.slice(startIndex.value, endIndex.value);
    });

    const isAllSelected = computed(() => {
      return selectedIds.value.length > 0 && 
             selectedIds.value.length === paginatedMessages.value.length;
    });

    const isIndeterminate = computed(() => {
      return selectedIds.value.length > 0 && 
             selectedIds.value.length < paginatedMessages.value.length;
    });

    const hasFilters = computed(() => {
      return searchQuery.value || filters.value.status;
    });

    // Methods
    const getUserInfo = (msg) => {
      const user = msg.created_by || msg.user || msg.sender || msg.agent;
      
      if (user && user.name) {
        return {
          name: user.name,
          avatar: user.avatar || user.avatar_url || null
        };
      }
      
      const currentUser = store.getters.getCurrentUser;
      return {
        name: currentUser?.name || 'Sistema',
        avatar: currentUser?.avatar_url || null
      };
    };

    const loadMessages = async () => {
      loading.value = true;
      try {
        const response = await store.dispatch('scheduledMessages/getAll', filters.value);
        messages.value = response.data || [];
      } catch (error) {
        console.error('Erro ao carregar mensagens:', error);
        messages.value = [];
      } finally {
        loading.value = false;
      }
    };

    const onSearchChange = debounce(() => {
      currentPage.value = 1;
    }, 300);

    const sortBy = (field) => {
      if (sortField.value === field) {
        sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
      } else {
        sortField.value = field;
        sortDirection.value = 'asc';
      }
    };

    const applySort = () => {
      const [field, direction] = filters.value.sortBy.split('_');
      if (field === 'date') {
        sortField.value = 'scheduled_at';
      } else if (field === 'contact') {
        sortField.value = 'contact';
      }
      sortDirection.value = direction || 'asc';
    };

    const toggleSelect = (id) => {
      const index = selectedIds.value.indexOf(id);
      if (index > -1) {
        selectedIds.value.splice(index, 1);
      } else {
        selectedIds.value.push(id);
      }
    };

    const toggleSelectAll = () => {
      if (isAllSelected.value) {
        selectedIds.value = [];
      } else {
        selectedIds.value = paginatedMessages.value.map(msg => msg.id);
      }
    };

    const clearFilters = () => {
      searchQuery.value = '';
      filters.value.status = '';
      filters.value.sortBy = 'date_asc';
      currentPage.value = 1;
    };

    const formatDateTime = (date) => {
      if (!date) return '-';
      const d = new Date(date);
      const dateStr = d.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      });
      const timeStr = d.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit'
      });
      return `${dateStr} às ${timeStr}`;
    };

    const statusLabel = (status) => {
      const labels = {
        pending: 'Pendente',
        sent: 'Enviada',
        failed: 'Falhada'
      };
      return labels[status] || status;
    };

    const truncateMessage = (content, maxLength = 60) => {
      if (!content) return '-';
      return content.length > maxLength 
        ? content.substring(0, maxLength) + '...' 
        : content;
    };

    const getInitials = (name) => {
      if (!name) return '?';
      return name
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase()
        .substring(0, 2);
    };

    const getAvatarColor = (name) => {
      const colors = [
        '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b',
        '#10b981', '#06b6d4', '#6366f1', '#f97316'
      ];
      const index = (name || '').charCodeAt(0) % colors.length;
      return colors[index];
    };

    const viewMessage = (msg) => {
      viewingMessage.value = { ...msg };
      showViewModal.value = true;
    };

    const closeViewModal = () => {
      showViewModal.value = false;
      viewingMessage.value = {};
    };

    const deleteMessage = async (msg) => {
      if (!confirm('Deseja excluir esta mensagem agendada?')) return;
      
      try {
        await store.dispatch('scheduledMessages/delete', msg.id);
        await loadMessages();
      } catch (error) {
        console.error('Erro ao deletar:', error);
        alert('Erro ao excluir a mensagem. Tente novamente.');
      }
    };

    // Lifecycle
    onMounted(() => {
      loadMessages();
    });

    return {
      messages,
      loading,
      searchQuery,
      selectedIds,
      currentPage,
      perPage,
      sortField,
      sortDirection,
      filters,
      showViewModal,
      viewingMessage,
      filteredMessages,
      paginatedMessages,
      totalPages,
      startIndex,
      endIndex,
      isAllSelected,
      isIndeterminate,
      hasFilters,
      getUserInfo,
      loadMessages,
      onSearchChange,
      sortBy,
      applySort,
      toggleSelect,
      toggleSelectAll,
      clearFilters,
      formatDateTime,
      statusLabel,
      truncateMessage,
      getInitials,
      getAvatarColor,
      viewMessage,
      closeViewModal,
      deleteMessage
    };
  }
};
</script>

<style scoped lang="scss">
.scheduled-messages-view {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--white);
}

/* Header */
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--s-100);
  background: var(--white);

  &__left {
    display: flex;
    align-items: center;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 0;
    font-size: 20px;
    font-weight: 600;
    color: var(--s-900);
  }

  &__icon {
    width: 24px;
    height: 24px;
    color: var(--s-600);
  }
}

/* Toolbar */
.list-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-bottom: 1px solid var(--s-100);
  background: var(--s-25);
  gap: 16px;
  flex-shrink: 0;
  min-height: 72px;

  &__left {
    display: flex;
    align-items: center;
    gap: 16px;
    flex: 1;
  }

  &__search {
    position: relative;
    flex: 1;
    max-width: 400px;

    input {
      width: 100%;
      height: 40px;
      padding: 10px 16px;
      border: 1px solid var(--s-200);
      border-radius: 6px;
      font-size: 14px;
      background: var(--white);
      color: var(--s-900);

      &:focus {
        outline: none;
        border-color: var(--w-500);
      }

      &::placeholder {
        color: var(--s-400);
      }
    }
  }

  &__count {
    font-size: 13px;
    color: var(--s-500);
    white-space: nowrap;
  }

  &__right {
    display: flex;
    gap: 12px;
    flex-shrink: 0;
    align-items: center;
  }

  &__filter {
    min-width: 160px;
    height: 40px;
    padding: 10px 14px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 14px;
    background: var(--white);
    color: var(--s-900);
    cursor: pointer;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }

    option {
      background: var(--white);
      color: var(--s-900);
      padding: 8px;
    }
  }

  &__clear {
    height: 40px;
    padding: 10px 16px;
    background: var(--s-100);
    border: none;
    border-radius: 6px;
    font-size: 13px;
    color: var(--s-700);
    cursor: pointer;
    white-space: nowrap;

    &:hover {
      background: var(--s-200);
    }
  }
}

/* Loading */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 24px;
  gap: 16px;
  color: var(--s-500);
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--s-200);
  border-top-color: var(--w-500);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Table */
.list-table-container {
  flex: 1;
  overflow: auto;
  width: 100%;
  min-width: 0;
  min-height: 0;

  &::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }

  &::-webkit-scrollbar-track {
    background: var(--s-50);
  }

  &::-webkit-scrollbar-thumb {
    background: var(--s-300);
    border-radius: 4px;

    &:hover {
      background: var(--s-400);
    }
  }
}

.list-table {
  width: 100%;
  table-layout: fixed;
  border-collapse: collapse;
  font-size: 14px;

  &__th {
    position: sticky;
    top: 0;
    padding: 14px 16px;
    text-align: left;
    font-weight: 600;
    font-size: 12px;
    text-transform: uppercase;
    color: var(--s-600);
    background: #ffffff;
    background-color: #ffffff;
    border-bottom: 2px solid var(--s-200);
    white-space: nowrap;
    z-index: 100;

    &--sortable {
      cursor: pointer;
      user-select: none;

      &:hover {
        color: var(--s-900);
      }

      .sort-icon {
        margin-left: 4px;
        color: var(--w-500);
      }
    }

    &--checkbox {
      width: 48px;
    }

    &--actions {
      width: 80px;
      text-align: right;
    }
  }

  // Coluna de status com largura fixa
  &__th:nth-child(4),
  &__td:nth-child(4) {
    width: 120px;
  }

  &__row {
    transition: background 0.15s;
    cursor: pointer;

    &:hover {
      background: #f8f8f8;
      background-color: #f8f8f8;
    }

    &--selected {
      background: var(--w-50);

      &:hover {
        background: var(--w-100);
      }
    }
  }

  &__td {
    padding: 14px 16px;
    border-bottom: 1px solid var(--s-100);
    color: var(--s-700);

    &--checkbox {
      width: 48px;
    }

    &--name {
      width: 220px;
    }

    &--date {
      width: 180px;
    }

    &--message {
      width: auto;
      min-width: 0;
    }

    &--user {
      width: 180px;
    }

    &--date-small {
      width: 160px;
      font-size: 13px;
      color: var(--s-600);
    }

    &--actions {
      width: 80px;
      text-align: right;
    }
  }

  &__empty {
    padding: 60px 24px;
    text-align: center;
  }
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 12px;
}

.contact-avatar-img,
.contact-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  flex-shrink: 0;
}

.contact-avatar-img {
  object-fit: cover;
}

.contact-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
  font-weight: 600;
  font-size: 14px;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;

  &__name {
    font-weight: 500;
    color: var(--s-900);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__phone {
    font-size: 12px;
    color: var(--s-500);
  }
}

.scheduled-date {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 500;
  color: var(--s-800);

  svg {
    width: 16px;
    height: 16px;
    color: var(--s-400);
    flex-shrink: 0;
  }
}

.status-badge {
  display: inline-flex;
  padding: 5px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;

  &--large {
    padding: 8px 16px;
    font-size: 14px;
  }

  &--pending {
    background: #fef3c7;
    color: #92400e;
  }

  &--sent {
    background: #d1fae5;
    color: #065f46;
  }

  &--failed {
    background: #fee2e2;
    color: #991b1b;
  }
}

.message-preview {
  color: var(--s-600);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-avatar-img,
.user-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  flex-shrink: 0;
}

.user-avatar-img {
  object-fit: cover;
}

.user-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
  font-weight: 600;
  font-size: 11px;
}

.user-name {
  font-size: 13px;
  color: var(--s-700);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.actions-menu {
  display: flex;
  gap: 6px;
  justify-content: flex-end;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  padding: 0;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background: var(--white);
  cursor: pointer;
  transition: all 0.15s;

  svg {
    width: 15px;
    height: 15px;
    color: var(--s-600);
  }

  &:hover {
    background: var(--s-50);
    border-color: var(--s-300);

    svg {
      color: var(--s-900);
    }
  }

  &--danger {
    &:hover {
      background: #fee2e2;
      border-color: #fecaca;

      svg {
        color: #991b1b;
      }
    }
  }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: var(--s-500);

  svg {
    width: 48px;
    height: 48px;
    color: var(--s-300);
  }

  span {
    font-size: 14px;
  }
}

/* Pagination */
.list-pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  border-top: 1px solid var(--s-100);
  background: var(--s-25);
  flex-shrink: 0;

  &__info {
    font-size: 13px;
    color: var(--s-500);
  }

  &__controls {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  &__per-page {
    padding: 8px 12px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 13px;
    background: var(--white);
    color: var(--s-900);
    cursor: pointer;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }

    option {
      background: var(--white);
      color: var(--s-900);
      padding: 8px;
    }
  }

  &__buttons {
    display: flex;
    gap: 8px;
  }
}

.pagination-btn {
  padding: 8px 12px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background: var(--white);
  color: var(--s-900);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;

  &:hover:not(:disabled) {
    background: var(--s-50);
    border-color: var(--s-300);
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

.pagination-info {
  font-size: 13px;
  color: var(--s-600);
  padding: 0 8px;
}

/* Modal de Visualização */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: #1a1d21;
  border-radius: 12px;
  width: 600px;
  max-width: 100%;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
  position: relative;

  &--view {
    width: 600px;
  }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
  background: #1a1d21;
  border-radius: 12px 12px 0 0;

  h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
    color: #ffffff;
  }
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: rgba(255, 255, 255, 0.5);
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  transition: all 0.2s;

  &:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #ffffff;
  }
}

.modal-body {
  padding: 24px;
  overflow-y: auto;
  flex: 1;
  background: #1a1d21;
  border-radius: 0 0 12px 12px;

  &::-webkit-scrollbar {
    width: 6px;
  }

  &::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.05);
  }

  &::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.2);
    border-radius: 3px;

    &:hover {
      background: rgba(255, 255, 255, 0.3);
    }
  }
}

.view-section {
  margin-bottom: 20px;

  &:last-child {
    margin-bottom: 0;
  }

  &__title {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    color: rgba(255, 255, 255, 0.5);
    margin: 0 0 10px 0;
    letter-spacing: 0.8px;
  }
}

.view-section-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
}

.contact-detail {
  display: flex;
  align-items: center;
  gap: 14px;

  &__avatar {
    width: 52px;
    height: 52px;
    border-radius: 50%;
    object-fit: cover;
    flex-shrink: 0;

    &--initials {
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--white);
      font-weight: 600;
      font-size: 18px;
    }
  }

  &__info {
    flex: 1;
    min-width: 0;
  }

  &__name {
    font-size: 17px;
    font-weight: 600;
    color: #ffffff;
    margin-bottom: 4px;
  }

  &__phone {
    font-size: 13px;
    color: rgba(255, 255, 255, 0.6);
  }
}

.view-info {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  color: #ffffff;
  font-weight: 500;

  svg {
    width: 16px;
    height: 16px;
    color: rgba(255, 255, 255, 0.5);
    flex-shrink: 0;
  }
}

.message-full {
  padding: 14px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.6;
  font-size: 14px;
  white-space: pre-wrap;
  word-wrap: break-word;
  max-height: 200px;
  overflow-y: auto;

  &::-webkit-scrollbar {
    width: 6px;
  }

  &::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 3px;
  }

  &::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.2);
    border-radius: 3px;

    &:hover {
      background: rgba(255, 255, 255, 0.3);
    }
  }
}

.user-detail {
  display: flex;
  align-items: center;
  gap: 10px;

  &__avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    object-fit: cover;
    flex-shrink: 0;

    &--initials {
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--white);
      font-weight: 600;
      font-size: 12px;
    }
  }

  &__name {
    font-size: 13px;
    color: rgba(255, 255, 255, 0.9);
    font-weight: 500;
  }
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.btn-close {
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  background: var(--w-500);
  border: none;
  color: var(--white);

  &:hover {
    background: var(--w-600);
  }
}
  
/* Dark Mode */
.dark {
  .scheduled-messages-view,
  .page-header {
    background: var(--s-900);
    border-bottom-color: var(--s-700);
  }

  .page-header__title {
    color: var(--s-100);
  }

  .list-toolbar {
    background: var(--s-800);
    border-bottom-color: var(--s-700);

    &__search input {
      background: var(--s-900);
      border-color: var(--s-700);
      color: var(--s-100);
    }

    &__filter {
      background: var(--s-900);
      border-color: var(--s-700);
      color: var(--s-200);

      option {
        background: var(--s-900) !important;
        background-color: var(--s-900) !important;
        color: var(--s-200) !important;
        -webkit-appearance: none !important;
        appearance: none !important;
      }
    }

    &__clear {
      background: var(--s-700);
      color: var(--s-200);

      &:hover {
        background: var(--s-600);
      }
    }
  }

  .list-table {
    &__th {
      background: var(--s-900);
      background-color: #1a1d21;
      border-bottom-color: #1a1d21;
      z-index: 100;
      color: var(--s-400);
    }

    &__row:hover {
      background: #2a2a2a;
      background-color: #2a2a2a;
    }

    &__td {
      border-bottom-color: var(--s-700);
      color: var(--s-300);
    }
  }

  .contact-info__name,
  .user-name {
    color: var(--s-100);
  }

  .action-btn {
    background: var(--s-800);
    border-color: var(--s-700);

    svg {
      color: var(--s-400);
    }

    &:hover {
      background: var(--s-700);
      border-color: var(--s-600);

      svg {
        color: var(--s-100);
      }
    }
  }

  .list-pagination {
    background: var(--s-800);
    border-top-color: var(--s-700);

    &__per-page {
      background: var(--s-900);
      border-color: var(--s-700);
      color: var(--s-200);

      option {
        background: var(--s-900) !important;
        color: var(--s-200) !important;
      }
    }
  }

  .pagination-btn {
    background: var(--s-900);
    border-color: var(--s-700);
    color: var(--s-200);

    &:hover:not(:disabled) {
      background: var(--s-700);
      border-color: var(--s-600);
    }
  }
}
</style>
