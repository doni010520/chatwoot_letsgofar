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
                  v-if="msg.created_by?.avatar" 
                  :src="msg.created_by.avatar" 
                  :alt="msg.created_by.name"
                  class="user-avatar-img"
                />
                <div v-else class="user-avatar" :style="{ backgroundColor: getAvatarColor(msg.created_by?.name) }">
                  {{ getInitials(msg.created_by?.name) }}
                </div>
                <span class="user-name">{{ msg.created_by?.name || '-' }}</span>
              </div>
            </td>
            <td class="list-table__td list-table__td--date-small">
              {{ formatDateTime(msg.created_at) }}
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

    <!-- Modal de Edição -->
    <div v-if="showEditModal" class="modal-overlay" @click.self="closeEditModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>Editar Mensagem Agendada</h3>
          <button class="modal-close" @click="closeEditModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Contato</label>
            <input 
              type="text" 
              :value="editingMessage.contact?.name" 
              disabled
              class="form-input form-input--disabled"
            />
          </div>
          <div class="form-group">
            <label>Data/Hora</label>
            <input 
              v-model="editingMessage.scheduled_at" 
              type="datetime-local"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label>Mensagem</label>
            <textarea 
              v-model="editingMessage.content" 
              rows="4"
              class="form-textarea"
            ></textarea>
          </div>
          <div class="modal-actions">
            <button class="btn-cancel" @click="closeEditModal">Cancelar</button>
            <button class="btn-save" @click="saveMessage">Salvar</button>
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
    const showEditModal = ref(false);
    const editingMessage = ref({});
    
    const filters = ref({
      search: '',
      status: '',
      sortBy: 'date_asc'
    });

    // Computed
    const filteredMessages = computed(() => {
      let result = [...messages.value];

      // Filtro de busca (contato E mensagem)
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
          case 'created_by':
            aVal = a.created_by?.name || '';
            bVal = b.created_by?.name || '';
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
      editingMessage.value = { ...msg };
      showEditModal.value = true;
    };

    const closeEditModal = () => {
      showEditModal.value = false;
      editingMessage.value = {};
    };

    const saveMessage = async () => {
      try {
        await store.dispatch('scheduledMessages/update', editingMessage.value);
        await loadMessages();
        closeEditModal();
      } catch (error) {
        console.error('Erro ao salvar:', error);
      }
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
      showEditModal,
      editingMessage,
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
      statusLabel,
      truncateMessage,
      getInitials,
      getAvatarColor,
      editMessage,
      closeEditModal,
      saveMessage,
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

.btn-new {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
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
  gap: 16px;

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
  }

  &__filter {
    min-width: 160px;
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
    padding: 14px 16px;
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
      width: 48px;
    }

    &--actions {
      width: 120px;
      text-align: right;
    }
  }

  &__row {
    transition: background 0.15s;

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
    padding: 14px 16px;
    border-bottom: 1px solid var(--s-100);
    color: var(--s-700);

    &--checkbox {
      width: 48px;
    }

    &--name {
      min-width: 200px;
    }

    &--date {
      min-width: 180px;
    }

    &--message {
      max-width: 300px;
    }

    &--user {
      min-width: 160px;
    }

    &--date-small {
      min-width: 160px;
      font-size: 13px;
      color: var(--s-600);
    }

    &--actions {
      width: 120px;
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

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--white);
  border-radius: 12px;
  width: 500px;
  max-width: 90%;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--s-100);

  h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
    color: var(--s-900);
  }
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: var(--s-400);
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;

  &:hover {
    background: var(--s-50);
    color: var(--s-900);
  }
}

.modal-body {
  padding: 24px;
}

.form-group {
  margin-bottom: 20px;

  label {
    display: block;
    margin-bottom: 8px;
    font-size: 14px;
    font-weight: 500;
    color: var(--s-700);
  }
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 14px;
  color: var(--s-900);
  background: var(--white);
  font-family: inherit;

  &:focus {
    outline: none;
    border-color: var(--w-500);
  }

  &--disabled {
    background: var(--s-50);
    color: var(--s-500);
    cursor: not-allowed;
  }
}

.form-textarea {
  resize: vertical;
  min-height: 100px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}

.btn-cancel,
.btn-save {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: var(--white);
  border: 1px solid var(--s-200);
  color: var(--s-700);

  &:hover {
    background: var(--s-50);
  }
}

.btn-save {
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
        background: var(--s-900);
        color: var(--s-200);
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
        background: var(--s-900);
        color: var(--s-200);
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

  .modal-content {
    background: var(--s-800);
  }

  .modal-header {
    border-bottom-color: var(--s-700);

    h3 {
      color: var(--s-100);
    }
  }

  .form-input,
  .form-textarea {
    background: var(--s-900);
    border-color: var(--s-700);
    color: var(--s-100);
  }

  .btn-cancel {
    background: var(--s-900);
    border-color: var(--s-700);
    color: var(--s-200);

    &:hover {
      background: var(--s-700);
    }
  }
}
</style>
