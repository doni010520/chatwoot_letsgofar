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
      <div class="page-header__actions">
        <button class="btn-new" @click="openScheduleModal">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/>
            <line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Agendar Nova
        </button>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="list-toolbar">
      <div class="list-toolbar__left">
        <div class="list-toolbar__search">
          <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar por contato..."
            @input="onSearchChange"
          />
        </div>
        <span class="list-toolbar__count">
          {{ filteredMessages.length }} de {{ messages.length }} mensagens
        </span>
      </div>
      <div class="list-toolbar__right">
        <select v-model="filters.status" class="list-toolbar__filter" @change="loadMessages">
          <option value="">Todos os status</option>
          <option value="pending">Pendentes</option>
          <option value="sent">Enviadas</option>
          <option value="failed">Falhadas</option>
        </select>
        <select v-model="filters.sortBy" class="list-toolbar__filter" @change="applySort">
          <option value="date_asc">Mais próximas</option>
          <option value="date_desc">Mais distantes</option>
          <option value="contact">Contato (A-Z)</option>
        </select>
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
              <span>Data/Hora Agendada</span>
              <span class="sort-icon" v-if="sortField === 'scheduled_at'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th">Status</th>
            <th class="list-table__th">Mensagem</th>
            <th class="list-table__th list-table__th--sortable" @click="sortBy('updated_at')">
              <span>Última Atualização</span>
              <span class="sort-icon" v-if="sortField === 'updated_at'">
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
                <div class="contact-avatar" :style="{ backgroundColor: getAvatarColor(msg.contact.name) }">
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
            <td class="list-table__td list-table__td--date-small">
              {{ formatDate(msg.updated_at) }}
            </td>
            <td class="list-table__td list-table__td--actions" @click.stop>
              <div class="actions-menu">
                <button class="action-btn" title="Editar" @click="editMessage(msg)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
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
            <td colspan="7" class="list-table__empty">
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
        <select v-model="perPage" class="list-pagination__per-page" @change="currentPage = 1">
          <option :value="10">10 por página</option>
          <option :value="25">25 por página</option>
          <option :value="50">50 por página</option>
          <option :value="100">100 por página</option>
        </select>
        <div class="list-pagination__buttons">
          <button class="pagination-btn" :disabled="currentPage === 1" @click="currentPage = 1">««</button>
          <button class="pagination-btn" :disabled="currentPage === 1" @click="currentPage--">«</button>
          <span class="pagination-info">Página {{ currentPage }} de {{ totalPages }}</span>
          <button class="pagination-btn" :disabled="currentPage === totalPages" @click="currentPage++">»</button>
          <button class="pagination-btn" :disabled="currentPage === totalPages" @click="currentPage = totalPages">»»</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { debounce } from '@chatwoot/utils';

export default {
  name: 'ScheduledMessages',
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
    
    const filters = ref({
      search: '',
      status: '',
      sortBy: 'date_asc'
    });

    // Computed
    const filteredMessages = computed(() => {
      let result = [...messages.value];

      // Filtro de busca
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        result = result.filter(msg => 
          msg.contact?.name?.toLowerCase().includes(query) ||
          msg.contact?.phone?.includes(query) ||
          msg.content?.toLowerCase().includes(query)
        );
      }

      // Filtro de status
      if (filters.value.status) {
        result = result.filter(msg => msg.status === filters.value.status);
      }

      // Ordenação
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
          case 'updated_at':
            aVal = new Date(a.updated_at);
            bVal = new Date(b.updated_at);
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
      return d.toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    };

    const formatDate = (date) => {
      if (!date) return '-';
      const d = new Date(date);
      const now = new Date();
      const diff = Math.floor((now - d) / 1000);

      if (diff < 60) return 'Agora';
      if (diff < 3600) return `${Math.floor(diff / 60)}min atrás`;
      if (diff < 86400) return `${Math.floor(diff / 3600)}h atrás`;
      if (diff < 172800) return 'Ontem';
      
      return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
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

    const editMessage = (msg) => {
      // TODO: Implementar edição
      console.log('Editar:', msg);
    };

    const deleteMessage = async (msg) => {
      if (!confirm('Deseja excluir esta mensagem agendada?')) return;
      
      try {
        await store.dispatch('scheduledMessages/delete', msg.id);
        await loadMessages();
      } catch (error) {
        console.error('Erro ao deletar:', error);
      }
    };

    const openScheduleModal = () => {
      // TODO: Abrir modal de agendamento
      console.log('Agendar nova mensagem');
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
      filteredMessages,
      paginatedMessages,
      totalPages,
      startIndex,
      endIndex,
      isAllSelected,
      isIndeterminate,
      hasFilters,
      loadMessages,
      onSearchChange,
      sortBy,
      applySort,
      toggleSelect,
      toggleSelectAll,
      clearFilters,
      formatDateTime,
      formatDate,
      statusLabel,
      truncateMessage,
      getInitials,
      getAvatarColor,
      editMessage,
      deleteMessage,
      openScheduleModal
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
  padding: 16px 24px;
  border-bottom: 1px solid var(--s-100);
  background: var(--white);

  &__left {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 10px;
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

  &__actions {
    display: flex;
    gap: 12px;
  }
}

.btn-new {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: var(--w-500);
  color: var(--white);
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;

  svg {
    width: 16px;
    height: 16px;
  }

  &:hover {
    background: var(--w-600);
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

    .search-icon {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      width: 16px;
      height: 16px;
      color: var(--s-400);
    }

    input {
      width: 100%;
      padding: 8px 12px 8px 36px;
      border: 1px solid var(--s-200);
      border-radius: 6px;
      font-size: 14px;
      background: var(--white);

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
  }

  &__filter {
    padding: 8px 12px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 14px;
    background: var(--white);
    cursor: pointer;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }
  }

  &__clear {
    padding: 8px 12px;
    background: var(--s-100);
    border: none;
    border-radius: 6px;
    font-size: 13px;
    color: var(--s-700);
    cursor: pointer;

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
  border-collapse: collapse;
  font-size: 14px;

  &__th {
    position: sticky;
    top: 0;
    padding: 12px 16px;
    text-align: left;
    font-weight: 600;
    font-size: 12px;
    text-transform: uppercase;
    color: var(--s-600);
    background: var(--s-50);
    border-bottom: 2px solid var(--s-200);
    white-space: nowrap;
    z-index: 1;

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
      width: 40px;
    }

    &--actions {
      width: 100px;
      text-align: right;
    }
  }

  &__row {
    transition: background 0.15s;
    cursor: pointer;

    &:hover {
      background: var(--s-25);
    }

    &--selected {
      background: var(--w-50);

      &:hover {
        background: var(--w-100);
      }
    }
  }

  &__td {
    padding: 12px 16px;
    border-bottom: 1px solid var(--s-100);
    color: var(--s-700);

    &--checkbox {
      width: 40px;
    }

    &--name {
      min-width: 200px;
    }

    &--date {
      min-width: 180px;
    }

    &--date-small {
      min-width: 120px;
      font-size: 13px;
      color: var(--s-500);
    }

    &--message {
      max-width: 300px;
    }

    &--actions {
      width: 100px;
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

.contact-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
  font-weight: 600;
  font-size: 13px;
  flex-shrink: 0;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
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

  svg {
    width: 14px;
    height: 14px;
    color: var(--s-400);
    flex-shrink: 0;
  }
}

.status-badge {
  display: inline-flex;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;

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
  line-height: 1.4;
}

.actions-menu {
  display: flex;
  gap: 4px;
  justify-content: flex-end;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background: var(--white);
  cursor: pointer;
  transition: all 0.15s;

  svg {
    width: 14px;
    height: 14px;
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
  padding: 12px 24px;
  border-top: 1px solid var(--s-100);
  background: var(--s-25);

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
    padding: 6px 10px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 13px;
    background: var(--white);
    cursor: pointer;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }
  }

  &__buttons {
    display: flex;
    gap: 8px;
  }
}

.pagination-btn {
  padding: 6px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background: var(--white);
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

/* Dark Mode */
.dark {
  .scheduled-messages-view {
    background: var(--s-900);
  }

  .page-header {
    background: var(--s-900);
    border-bottom-color: var(--s-700);

    &__title {
      color: var(--s-100);
    }

    &__icon {
      color: var(--s-400);
    }
  }

  .list-toolbar {
    background: var(--s-800);
    border-bottom-color: var(--s-700);

    &__search {
      input {
        background: var(--s-900);
        border-color: var(--s-700);
        color: var(--s-100);
      }
    }

    &__filter {
      background: var(--s-900);
      border-color: var(--s-700);
      color: var(--s-200);
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
      background: var(--s-800);
      border-bottom-color: var(--s-700);
      color: var(--s-400);
    }

    &__row:hover {
      background: var(--s-800);
    }

    &__td {
      border-bottom-color: var(--s-700);
      color: var(--s-300);
    }
  }

  .contact-info__name {
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
/app/javascript/dashboard/routes/dashboard/schedule_messages/Index.vue
