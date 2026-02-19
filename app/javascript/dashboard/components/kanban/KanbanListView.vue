<template>
  <div class="kanban-list-view">
    <!-- Barra de ferramentas -->
    <div class="list-toolbar">
      <div class="list-toolbar__left">
        <div class="list-toolbar__search">
          <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar por nome, email, telefone..."
            @input="onSearchChange"
          />
        </div>
        <span class="list-toolbar__count">
          {{ filteredItems.length }} de {{ allItems.length }} registros
        </span>
      </div>
      <div class="list-toolbar__right">
        <select v-model="stageFilter" class="list-toolbar__filter" @change="applyFilters">
          <option value="">Todos os estágios</option>
          <option v-for="stage in stages" :key="stage.id" :value="stage.id">
            {{ stage.name }}
          </option>
        </select>
        <select v-model="assigneeFilter" class="list-toolbar__filter" @change="applyFilters">
          <option value="">Todos os responsáveis</option>
          <option v-for="user in assignees" :key="user.id" :value="user.id">
            {{ user.name }}
          </option>
        </select>
        <button v-if="hasFilters" class="list-toolbar__clear" @click="clearFilters">
          Limpar filtros
        </button>
      </div>
    </div>

    <!-- Tabela -->
    <div class="list-table-container">
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
            <th
              class="list-table__th list-table__th--sortable"
              @click="sortBy('name')"
            >
              <span>Nome</span>
              <span class="sort-icon" v-if="sortField === 'name'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th
              class="list-table__th list-table__th--sortable"
              @click="sortBy('stage')"
            >
              <span>Estágio</span>
              <span class="sort-icon" v-if="sortField === 'stage'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th
              class="list-table__th list-table__th--sortable list-table__th--right"
              @click="sortBy('value')"
            >
              <span>Valor</span>
              <span class="sort-icon" v-if="sortField === 'value'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th">Responsável</th>
            <th class="list-table__th">Contato</th>
            <th
              class="list-table__th list-table__th--sortable"
              @click="sortBy('updated_at')"
            >
              <span>Última atualização</span>
              <span class="sort-icon" v-if="sortField === 'updated_at'">
                {{ sortDirection === 'asc' ? '↑' : '↓' }}
              </span>
            </th>
            <th class="list-table__th list-table__th--actions">Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="item in paginatedItems"
            :key="`${item.type}-${item.id}`"
            class="list-table__row"
            :class="{ 'list-table__row--selected': selectedItems.includes(item.id) }"
            @click="$emit('card-click', { item, itemType: item.type })"
          >
            <td class="list-table__td list-table__td--checkbox" @click.stop>
              <input
                type="checkbox"
                :checked="selectedItems.includes(item.id)"
                @change="toggleSelect(item.id)"
              />
            </td>
            <td class="list-table__td list-table__td--name">
              <div class="item-name">
                <div class="item-avatar" :style="{ backgroundColor: getAvatarColor(item.name) }">
                  {{ getInitials(item.name) }}
                </div>
                <div class="item-info">
                  <span class="item-info__name">{{ item.name || 'Sem nome' }}</span>
                  <span class="item-info__id">#{{ item.display_id || item.id }}</span>
                </div>
              </div>
            </td>
            <td class="list-table__td">
              <span
                class="stage-badge"
                :style="{ backgroundColor: item.stage_color + '20', color: item.stage_color }"
              >
                {{ item.stage_name }}
              </span>
            </td>
            <td class="list-table__td list-table__td--right list-table__td--value">
              {{ formatCurrency(item.deal_value) }}
            </td>
            <td class="list-table__td">
              <div v-if="item.assignee" class="assignee">
                <img
                  v-if="item.assignee.avatar_url"
                  :src="item.assignee.avatar_url"
                  :alt="item.assignee.name"
                  class="assignee__avatar"
                />
                <div v-else class="assignee__avatar assignee__avatar--placeholder">
                  {{ getInitials(item.assignee.name) }}
                </div>
                <span class="assignee__name">{{ item.assignee.name }}</span>
              </div>
              <span v-else class="text-muted">Não atribuído</span>
            </td>
            <td class="list-table__td">
              <div class="contact-info">
                <span v-if="item.email" class="contact-info__item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                    <polyline points="22,6 12,13 2,6"/>
                  </svg>
                  {{ item.email }}
                </span>
                <span v-if="item.phone" class="contact-info__item">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
                  </svg>
                  {{ item.phone }}
                </span>
                <span v-if="!item.email && !item.phone" class="text-muted">-</span>
              </div>
            </td>
            <td class="list-table__td list-table__td--date">
              {{ formatDate(item.updated_at) }}
            </td>
            <td class="list-table__td list-table__td--actions" @click.stop>
              <div class="actions-menu">
                <button class="action-btn" title="Abrir" @click="$emit('card-click', { item, itemType: item.type })">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
                    <polyline points="15 3 21 3 21 9"/>
                    <line x1="10" y1="14" x2="21" y2="3"/>
                  </svg>
                </button>
                <button class="action-btn action-btn--success" title="Marcar como Ganho" @click="$emit('mark-won', { itemId: item.id })">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </button>
                <button class="action-btn action-btn--danger" title="Marcar como Perdido" @click="$emit('mark-lost', { itemId: item.id })">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                </button>
                <div class="action-dropdown">
                  <button class="action-btn" title="Mais opções" @click="toggleDropdown(item.id)">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <circle cx="12" cy="12" r="1"/>
                      <circle cx="19" cy="12" r="1"/>
                      <circle cx="5" cy="12" r="1"/>
                    </svg>
                  </button>
                  <div v-if="openDropdown === item.id" class="dropdown-menu">
                    <button @click="moveToStage(item)">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M5 12h14M12 5l7 7-7 7"/>
                      </svg>
                      Mover para estágio
                    </button>
                    <button @click="$emit('remove', { itemId: item.id, itemType: item.type })">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="3 6 5 6 21 6"/>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                      </svg>
                      Remover do CRM
                    </button>
                  </div>
                </div>
              </div>
            </td>
          </tr>
          <tr v-if="paginatedItems.length === 0">
            <td colspan="8" class="list-table__empty">
              <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
                <span>Nenhum registro encontrado</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Paginação -->
    <div class="list-pagination">
      <div class="list-pagination__info">
        Mostrando {{ startIndex + 1 }} - {{ endIndex }} de {{ filteredItems.length }}
      </div>
      <div class="list-pagination__controls">
        <select v-model="perPage" class="list-pagination__per-page" @change="currentPage = 1">
          <option :value="10">10 por página</option>
          <option :value="25">25 por página</option>
          <option :value="50">50 por página</option>
          <option :value="100">100 por página</option>
        </select>
        <div class="list-pagination__buttons">
          <button
            class="pagination-btn"
            :disabled="currentPage === 1"
            @click="currentPage = 1"
          >
            ««
          </button>
          <button
            class="pagination-btn"
            :disabled="currentPage === 1"
            @click="currentPage--"
          >
            «
          </button>
          <span class="pagination-info">
            Página {{ currentPage }} de {{ totalPages }}
          </span>
          <button
            class="pagination-btn"
            :disabled="currentPage === totalPages"
            @click="currentPage++"
          >
            »
          </button>
          <button
            class="pagination-btn"
            :disabled="currentPage === totalPages"
            @click="currentPage = totalPages"
          >
            »»
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Mover para Estágio -->
    <div v-if="showMoveModal" class="modal-overlay" @click.self="showMoveModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>Mover para estágio</h3>
          <button class="modal-close" @click="showMoveModal = false">×</button>
        </div>
        <div class="modal-body">
          <p>Mover <strong>{{ selectedItemForMove?.name }}</strong> para:</p>
          <div class="stage-options">
            <button
              v-for="stage in stages"
              :key="stage.id"
              class="stage-option"
              :class="{ 'stage-option--active': stage.id === selectedItemForMove?.stage_id }"
              :style="{ borderColor: stage.color }"
              @click="confirmMove(stage.id)"
            >
              <span class="stage-option__color" :style="{ backgroundColor: stage.color }"></span>
              {{ stage.name }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanListView',
  props: {
    board: {
      type: Object,
      required: true,
    },
    stages: {
      type: Array,
      default: () => [],
    },
    assignees: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['card-click', 'move', 'mark-won', 'mark-lost', 'remove'],
  data() {
    return {
      searchQuery: '',
      stageFilter: '',
      assigneeFilter: '',
      sortField: 'updated_at',
      sortDirection: 'desc',
      selectedItems: [],
      currentPage: 1,
      perPage: 25,
      openDropdown: null,
      showMoveModal: false,
      selectedItemForMove: null,
      searchTimeout: null,
    };
  },
  computed: {
    allItems() {
      // board é um array de { stage, items, totals }
      if (!this.board || !Array.isArray(this.board)) return [];
      
      const items = [];
      this.board.forEach(stageData => {
        const stage = stageData.stage;
        const stageItems = stageData.items || [];
        stageItems.forEach(item => {
          items.push({
            ...item,
            // Dados do contato
            name: item.contact?.name || 'Sem nome',
            email: item.contact?.email || null,
            phone: item.contact?.phone_number || null,
            thumbnail: item.contact?.thumbnail || null,
            // Dados do estágio
            stage_id: stage.id,
            stage_name: stage.name,
            stage_color: stage.color || '#6b7280',
            // Tipo do item
            type: 'conversation',
            // Data de atualização
            updated_at: item.last_activity_at,
          });
        });
      });
      return items;
    },
    filteredItems() {
      let items = [...this.allItems];

      // Filtro de busca
      if (this.searchQuery) {
        const query = this.searchQuery.toLowerCase();
        items = items.filter(item => {
          return (
            (item.name && item.name.toLowerCase().includes(query)) ||
            (item.email && item.email.toLowerCase().includes(query)) ||
            (item.phone && item.phone.includes(query)) ||
            (item.display_id && item.display_id.toString().includes(query))
          );
        });
      }

      // Filtro por estágio
      if (this.stageFilter) {
        items = items.filter(item => item.stage_id === parseInt(this.stageFilter));
      }

      // Filtro por responsável
      if (this.assigneeFilter) {
        items = items.filter(item => item.assignee?.id === parseInt(this.assigneeFilter));
      }

      // Ordenação
      items.sort((a, b) => {
        let aVal, bVal;

        switch (this.sortField) {
          case 'name':
            aVal = (a.name || '').toLowerCase();
            bVal = (b.name || '').toLowerCase();
            break;
          case 'stage':
            aVal = a.stage_name.toLowerCase();
            bVal = b.stage_name.toLowerCase();
            break;
          case 'value':
            aVal = parseFloat(a.deal_value) || 0;
            bVal = parseFloat(b.deal_value) || 0;
            break;
          case 'updated_at':
            aVal = new Date(a.updated_at).getTime();
            bVal = new Date(b.updated_at).getTime();
            break;
          default:
            return 0;
        }

        if (aVal < bVal) return this.sortDirection === 'asc' ? -1 : 1;
        if (aVal > bVal) return this.sortDirection === 'asc' ? 1 : -1;
        return 0;
      });

      return items;
    },
    paginatedItems() {
      const start = (this.currentPage - 1) * this.perPage;
      const end = start + this.perPage;
      return this.filteredItems.slice(start, end);
    },
    totalPages() {
      return Math.ceil(this.filteredItems.length / this.perPage) || 1;
    },
    startIndex() {
      return (this.currentPage - 1) * this.perPage;
    },
    endIndex() {
      return Math.min(this.currentPage * this.perPage, this.filteredItems.length);
    },
    hasFilters() {
      return this.searchQuery || this.stageFilter || this.assigneeFilter;
    },
    isAllSelected() {
      return this.paginatedItems.length > 0 && 
             this.paginatedItems.every(item => this.selectedItems.includes(item.id));
    },
    isIndeterminate() {
      const selectedCount = this.paginatedItems.filter(item => 
        this.selectedItems.includes(item.id)
      ).length;
      return selectedCount > 0 && selectedCount < this.paginatedItems.length;
    },
  },
  watch: {
    board: {
      handler() {
        this.currentPage = 1;
      },
      deep: true,
    },
  },
  mounted() {
    document.addEventListener('click', this.closeDropdown);
  },
  beforeUnmount() {
    document.removeEventListener('click', this.closeDropdown);
  },
  methods: {
    onSearchChange() {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = setTimeout(() => {
        this.currentPage = 1;
      }, 300);
    },
    applyFilters() {
      this.currentPage = 1;
    },
    clearFilters() {
      this.searchQuery = '';
      this.stageFilter = '';
      this.assigneeFilter = '';
      this.currentPage = 1;
    },
    sortBy(field) {
      if (this.sortField === field) {
        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
      } else {
        this.sortField = field;
        this.sortDirection = 'asc';
      }
    },
    toggleSelect(itemId) {
      const index = this.selectedItems.indexOf(itemId);
      if (index > -1) {
        this.selectedItems.splice(index, 1);
      } else {
        this.selectedItems.push(itemId);
      }
    },
    toggleSelectAll() {
      if (this.isAllSelected) {
        this.selectedItems = this.selectedItems.filter(
          id => !this.paginatedItems.find(item => item.id === id)
        );
      } else {
        const newIds = this.paginatedItems.map(item => item.id);
        this.selectedItems = [...new Set([...this.selectedItems, ...newIds])];
      }
    },
    toggleDropdown(itemId) {
      this.openDropdown = this.openDropdown === itemId ? null : itemId;
    },
    closeDropdown(e) {
      if (!e.target.closest('.action-dropdown')) {
        this.openDropdown = null;
      }
    },
    moveToStage(item) {
      this.selectedItemForMove = item;
      this.showMoveModal = true;
      this.openDropdown = null;
    },
    confirmMove(toStageId) {
      if (this.selectedItemForMove.stage_id !== toStageId) {
        this.$emit('move', {
          itemId: this.selectedItemForMove.id,
          itemType: this.selectedItemForMove.type,
          fromStageId: this.selectedItemForMove.stage_id,
          toStageId,
        });
      }
      this.showMoveModal = false;
      this.selectedItemForMove = null;
    },
    getInitials(name) {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .slice(0, 2)
        .join('')
        .toUpperCase();
    },
    getAvatarColor(name) {
      const colors = [
        '#3b82f6', '#ef4444', '#10b981', '#f59e0b', '#8b5cf6',
        '#ec4899', '#06b6d4', '#84cc16', '#f97316', '#6366f1',
      ];
      const index = (name || '').charCodeAt(0) % colors.length;
      return colors[index];
    },
    formatCurrency(value) {
      const num = parseFloat(value) || 0;
      return num.toLocaleString('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      });
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      const date = new Date(dateString);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);

      if (diffMins < 60) return `${diffMins}min atrás`;
      if (diffHours < 24) return `${diffHours}h atrás`;
      if (diffDays < 7) return `${diffDays}d atrás`;
      
      return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-list-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--white);
}

.list-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding: 16px 24px;
  border-bottom: 1px solid var(--s-100);

  &__left {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  &__search {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    background: var(--s-50);
    border: 1px solid var(--s-200);
    border-radius: 8px;
    min-width: 300px;

    .search-icon {
      width: 16px;
      height: 16px;
      color: var(--s-400);
    }

    input {
      flex: 1;
      border: none;
      background: none;
      font-size: 14px;
      color: var(--s-800);
      outline: none;

      &::placeholder {
        color: var(--s-400);
      }
    }
  }

  &__count {
    font-size: 13px;
    color: var(--s-500);
  }

  &__right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__filter {
    padding: 8px 12px;
    border: 1px solid var(--s-200);
    border-radius: 8px;
    font-size: 13px;
    background: var(--white);
    color: var(--s-700);
    cursor: pointer;
  }

  &__clear {
    padding: 8px 12px;
    border: none;
    background: none;
    color: var(--w-500);
    font-size: 13px;
    cursor: pointer;

    &:hover {
      text-decoration: underline;
    }
  }
}

.list-table-container {
  flex: 1;
  overflow: auto;
}

.list-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 900px;

  &__th {
    position: sticky;
    top: 0;
    padding: 12px 16px;
    text-align: left;
    font-size: 12px;
    font-weight: 600;
    color: var(--s-500);
    text-transform: uppercase;
    background: var(--s-50);
    border-bottom: 1px solid var(--s-200);
    white-space: nowrap;

    &--sortable {
      cursor: pointer;
      user-select: none;

      &:hover {
        color: var(--s-700);
      }
    }

    &--checkbox {
      width: 40px;
    }

    &--right {
      text-align: right;
    }

    &--actions {
      width: 140px;
      text-align: center;
    }

    .sort-icon {
      margin-left: 4px;
      color: var(--w-500);
    }
  }

  &__row {
    cursor: pointer;
    transition: background-color 0.15s;

    &:hover {
      background: var(--s-25);
    }

    &--selected {
      background: rgba(59, 130, 246, 0.05);
    }
  }

  &__td {
    padding: 12px 16px;
    border-bottom: 1px solid var(--s-100);
    font-size: 14px;
    color: var(--s-700);
    vertical-align: middle;

    &--checkbox {
      width: 40px;
    }

    &--name {
      min-width: 200px;
    }

    &--right {
      text-align: right;
    }

    &--value {
      font-weight: 600;
      color: var(--s-800);
    }

    &--date {
      color: var(--s-500);
      font-size: 13px;
      white-space: nowrap;
    }

    &--actions {
      text-align: center;
    }
  }

  &__empty {
    padding: 60px;
    text-align: center;

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      color: var(--s-400);

      svg {
        width: 40px;
        height: 40px;
        opacity: 0.5;
      }
    }
  }
}

.item-name {
  display: flex;
  align-items: center;
  gap: 12px;
}

.item-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 600;
  color: white;
  flex-shrink: 0;
}

.item-info {
  display: flex;
  flex-direction: column;

  &__name {
    font-weight: 500;
    color: var(--s-800);
  }

  &__id {
    font-size: 12px;
    color: var(--s-400);
  }
}

.stage-badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
}

.assignee {
  display: flex;
  align-items: center;
  gap: 8px;

  &__avatar {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    object-fit: cover;

    &--placeholder {
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--s-200);
      color: var(--s-600);
      font-size: 11px;
      font-weight: 600;
    }
  }

  &__name {
    font-size: 13px;
  }
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 4px;

  &__item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: var(--s-600);

    svg {
      width: 12px;
      height: 12px;
      color: var(--s-400);
    }
  }
}

.text-muted {
  color: var(--s-400);
  font-size: 13px;
}

.actions-menu {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 6px;
  background: var(--s-50);
  cursor: pointer;
  transition: all 0.15s;

  svg {
    width: 14px;
    height: 14px;
    color: var(--s-500);
  }

  &:hover {
    background: var(--s-100);

    svg {
      color: var(--s-700);
    }
  }

  &--success:hover {
    background: rgba(16, 185, 129, 0.1);

    svg {
      color: #10b981;
    }
  }

  &--danger:hover {
    background: rgba(239, 68, 68, 0.1);

    svg {
      color: #ef4444;
    }
  }
}

.action-dropdown {
  position: relative;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 4px;
  padding: 4px;
  background: var(--white);
  border: 1px solid var(--s-200);
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 100;
  min-width: 180px;

  button {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 8px 12px;
    border: none;
    background: none;
    font-size: 13px;
    color: var(--s-700);
    cursor: pointer;
    border-radius: 6px;
    text-align: left;

    svg {
      width: 14px;
      height: 14px;
      color: var(--s-500);
    }

    &:hover {
      background: var(--s-50);
    }
  }
}

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
  }

  &__buttons {
    display: flex;
    align-items: center;
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
  width: 400px;
  max-width: 90%;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--s-100);

  h3 {
    margin: 0;
    font-size: 16px;
  }
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: var(--s-400);
  cursor: pointer;
}

.modal-body {
  padding: 20px;

  p {
    margin: 0 0 16px;
    color: var(--s-600);
  }
}

.stage-options {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stage-option {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  border: 2px solid var(--s-200);
  border-radius: 8px;
  background: var(--white);
  cursor: pointer;
  transition: all 0.15s;

  &:hover {
    background: var(--s-25);
  }

  &--active {
    background: var(--s-50);
  }

  &__color {
    width: 12px;
    height: 12px;
    border-radius: 50%;
  }
}

/* Dark Mode */
.dark {
  .kanban-list-view {
    background: var(--s-900);
  }

  .list-toolbar {
    border-bottom-color: var(--s-700);

    &__search {
      background: var(--s-800);
      border-color: var(--s-700);

      input {
        color: var(--s-100);
      }
    }

    &__filter {
      background: var(--s-800);
      border-color: var(--s-700);
      color: var(--s-200);
    }
  }

  .list-table {
    &__th {
      background: var(--s-800);
      color: var(--s-400);
      border-bottom-color: var(--s-700);
    }

    &__row:hover {
      background: var(--s-800);
    }

    &__td {
      border-bottom-color: var(--s-700);
      color: var(--s-300);
    }
  }

  .item-info__name {
    color: var(--s-100);
  }

  .action-btn {
    background: var(--s-800);

    svg {
      color: var(--s-400);
    }

    &:hover {
      background: var(--s-700);
    }
  }

  .dropdown-menu {
    background: var(--s-800);
    border-color: var(--s-700);

    button {
      color: var(--s-200);

      &:hover {
        background: var(--s-700);
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
    }
  }

  .modal-content {
    background: var(--s-800);
  }

  .modal-header {
    border-bottom-color: var(--s-700);
  }

  .stage-option {
    background: var(--s-900);
    border-color: var(--s-700);

    &:hover {
      background: var(--s-700);
    }
  }
}
</style>
