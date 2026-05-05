<template>
  <div class="kanban-tasks-notification" @click="toggleDropdown">
    <div class="notification-trigger" :class="{ 'has-urgent': urgentCount > 0 }">
      <span class="notification-icon">📋</span>
      <span v-if="urgentCount > 0" class="notification-badge">
        {{ urgentCount > 99 ? '99+' : urgentCount }}
      </span>
    </div>

    <!-- Dropdown -->
    <div v-if="showDropdown" class="notification-dropdown">
      <div class="dropdown-header">
        <span class="dropdown-title">Minhas Tarefas</span>
        <button class="dropdown-close" @click.stop="showDropdown = false">×</button>
      </div>

      <div v-if="loading" class="dropdown-loading">
        Carregando...
      </div>

      <div v-else class="dropdown-content">
        <!-- Resumo -->
        <div class="tasks-summary">
          <div
            v-if="summary.overdue > 0"
            class="summary-item summary-item--overdue summary-item--clickable"
            :class="{ 'summary-item--active': activeFilter === 'overdue' }"
            @click.stop="toggleFilter('overdue')"
          >
            <span class="summary-count">{{ summary.overdue }}</span>
            <span class="summary-label">Atrasadas</span>
          </div>
          <div
            v-if="summary.due_today > 0"
            class="summary-item summary-item--today summary-item--clickable"
            :class="{ 'summary-item--active': activeFilter === 'due_today' }"
            @click.stop="toggleFilter('due_today')"
          >
            <span class="summary-count">{{ summary.due_today }}</span>
            <span class="summary-label">Vence hoje</span>
          </div>
          <div
            v-if="summary.due_tomorrow > 0"
            class="summary-item summary-item--tomorrow summary-item--clickable"
            :class="{ 'summary-item--active': activeFilter === 'due_tomorrow' }"
            @click.stop="toggleFilter('due_tomorrow')"
          >
            <span class="summary-count">{{ summary.due_tomorrow }}</span>
            <span class="summary-label">Vence amanhã</span>
          </div>
          <div v-if="summary.total_pending === 0" class="summary-empty">
            Nenhuma tarefa pendente 🎉
          </div>
        </div>

        <!-- Barra de filtro ativo -->
        <div v-if="activeFilter" class="filter-bar">
          <span class="filter-bar__label">
            Filtrando: <strong>{{ filterLabel }}</strong>
            <span class="filter-bar__count">({{ filteredTasks.length }})</span>
          </span>
          <button class="filter-bar__clear" @click.stop="clearFilter">Limpar ×</button>
        </div>

        <!-- Lista de tarefas -->
        <div v-if="filteredTasks.length > 0" class="tasks-list">
          <div
            v-for="task in filteredTasks"
            :key="task.id"
            class="task-item"
            :class="{ 'task-item--overdue': task.overdue }"
            @click.stop="goToConversation(task)"
          >
            <div class="task-info">
              <span class="task-title">{{ task.title }}</span>
              <span class="task-contact">{{ task.conversation?.contact_name || 'Sem contato' }}</span>
            </div>
            <div class="task-due">
              {{ formatDueDate(task.due_at) }}
            </div>
          </div>
        </div>
        <div v-else-if="activeFilter" class="tasks-empty">
          Nenhuma tarefa para este filtro.
        </div>

        <!-- Link para ver todas -->
        <div class="dropdown-footer">
          <button class="view-all-btn" @click.stop="goToKanban">
            Ver Kanban →
          </button>
        </div>
      </div>
    </div>

    <!-- Overlay para fechar -->
    <div v-if="showDropdown" class="dropdown-overlay" @click="showDropdown = false"></div>
  </div>
</template>

<script>
import KanbanAPI from '../../api/kanban';

export default {
  name: 'KanbanTasksNotification',
  data() {
    return {
      showDropdown: false,
      loading: false,
      summary: {
        overdue: 0,
        due_today: 0,
        due_tomorrow: 0,
        total_pending: 0,
        urgent_count: 0,
      },
      tasks: [],
      pollInterval: null,
      activeFilter: null, // null | 'overdue' | 'due_today' | 'due_tomorrow'
    };
  },
  computed: {
    accountId() {
      return this.$route.params.accountId;
    },
    urgentCount() {
      return this.summary.urgent_count || 0;
    },
    filteredTasks() {
      // Tasks come pre-filtered from the backend based on activeFilter
      return this.tasks;
    },
    filterLabel() {
      const labels = {
        overdue: 'Atrasadas',
        due_today: 'Vence hoje',
        due_tomorrow: 'Vence amanhã',
      };
      return labels[this.activeFilter] || '';
    },
  },
  watch: {
    accountId: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.fetchSummary();
          this.startPolling();
        }
      },
    },
  },
  beforeUnmount() {
    this.stopPolling();
  },
  methods: {
    async fetchSummary() {
      if (!this.accountId) return;
      try {
        const response = await KanbanAPI.getUserTasksSummary(this.accountId);
        this.summary = response.data;
      } catch (error) {
        console.error('Error fetching tasks summary:', error);
      }
    },
    async fetchTasks() {
      if (!this.accountId) return;
      this.loading = true;
      try {
        // Map activeFilter to backend filter param. When no filter active, show this week.
        const filterMap = {
          overdue: 'overdue',
          due_today: 'today',
          due_tomorrow: 'tomorrow',
        };
        const apiFilter = filterMap[this.activeFilter] || 'week';
        const response = await KanbanAPI.getUserTasks(this.accountId, apiFilter);
        // Show more tasks when filtering (since user is looking for specific subset)
        const limit = this.activeFilter ? 50 : 10;
        this.tasks = response.data.slice(0, limit);
      } catch (error) {
        console.error('Error fetching tasks:', error);
      } finally {
        this.loading = false;
      }
    },
    toggleDropdown() {
      this.showDropdown = !this.showDropdown;
      if (this.showDropdown) {
        this.fetchTasks();
      } else {
        this.activeFilter = null;
      }
    },
    startPolling() {
      this.stopPolling();
      this.pollInterval = setInterval(() => {
        this.fetchSummary();
      }, 60000); // A cada 1 minuto
    },
    stopPolling() {
      if (this.pollInterval) {
        clearInterval(this.pollInterval);
        this.pollInterval = null;
      }
    },
    formatDueDate(dateStr) {
      if (!dateStr) return '';
      const date = new Date(dateStr);
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      const taskDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

      if (taskDate < today) {
        return 'Atrasada';
      } else if (taskDate.getTime() === today.getTime()) {
        return 'Hoje';
      } else if (taskDate.getTime() === tomorrow.getTime()) {
        return 'Amanhã';
      } else {
        return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
      }
    },
    goToConversation(task) {
      if (task.conversation?.display_id) {
        this.showDropdown = false;
        this.$router.push({
          name: 'inbox_conversation',
          params: {
            accountId: this.accountId,
            conversation_id: task.conversation.display_id,
          },
        });
      }
    },
    toggleFilter(filter) {
      // Toggle off if clicking the same filter again
      this.activeFilter = this.activeFilter === filter ? null : filter;
      this.fetchTasks();
    },
    clearFilter() {
      this.activeFilter = null;
      this.fetchTasks();
    },
    goToKanban() {
      this.showDropdown = false;
      this.$router.push({
        name: 'kanban_board',
        params: { accountId: this.accountId },
      });
    },
  },
};
</script>

<style scoped>
.kanban-tasks-notification {
  position: relative;
}

.notification-trigger {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
  position: relative;
}

.notification-trigger:hover {
  background-color: var(--s-100);
}

.notification-trigger.has-urgent {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.notification-icon {
  font-size: 20px;
}

.notification-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  background-color: #ef4444;
  color: white;
  font-size: 11px;
  font-weight: 600;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.notification-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  width: 320px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  z-index: 1000;
  margin-top: 8px;
  overflow: hidden;
}

.dropdown-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 999;
}

.dropdown-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background-color: #1f2937;
  color: white;
}

.dropdown-title {
  font-size: 14px;
  font-weight: 600;
}

.dropdown-close {
  background: none;
  border: none;
  color: white;
  font-size: 20px;
  cursor: pointer;
  opacity: 0.7;
}

.dropdown-close:hover {
  opacity: 1;
}

.dropdown-loading {
  padding: 24px;
  text-align: center;
  color: #6b7280;
}

.dropdown-content {
  max-height: 400px;
  overflow-y: auto;
}

.tasks-summary {
  display: flex;
  gap: 8px;
  padding: 12px;
  background-color: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}

.summary-item {
  flex: 1;
  text-align: center;
  padding: 8px;
  border-radius: 6px;
}

.summary-item--clickable {
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
}

.summary-item--clickable:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
}

.summary-item--active {
  outline: 2px solid #1f2937;
  outline-offset: -2px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.18);
}

.filter-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background-color: #eef2ff;
  border-bottom: 1px solid #e0e7ff;
  font-size: 12px;
  color: #3730a3;
}

.filter-bar__label {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.filter-bar__count {
  color: #6b7280;
  font-weight: 500;
}

.filter-bar__clear {
  background: none;
  border: none;
  color: #3730a3;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
}

.filter-bar__clear:hover {
  background-color: #e0e7ff;
}

.tasks-empty {
  padding: 24px 16px;
  text-align: center;
  font-size: 12px;
  color: #6b7280;
}

.summary-item--overdue {
  background-color: #fee2e2;
}

.summary-item--today {
  background-color: #fef3c7;
}

.summary-item--tomorrow {
  background-color: #dbeafe;
}

.summary-count {
  display: block;
  font-size: 20px;
  font-weight: 700;
}

.summary-item--overdue .summary-count {
  color: #dc2626;
}

.summary-item--today .summary-count {
  color: #d97706;
}

.summary-item--tomorrow .summary-count {
  color: #2563eb;
}

.summary-label {
  font-size: 10px;
  color: #6b7280;
  text-transform: uppercase;
}

.summary-empty {
  flex: 1;
  text-align: center;
  padding: 16px;
  color: #10b981;
  font-weight: 500;
}

.tasks-list {
  padding: 8px 0;
}

.task-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.task-item:hover {
  background-color: #f3f4f6;
}

.task-item--overdue {
  border-left: 3px solid #ef4444;
}

.task-info {
  flex: 1;
  min-width: 0;
}

.task-title {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #1f2937;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.task-contact {
  display: block;
  font-size: 11px;
  color: #6b7280;
  margin-top: 2px;
}

.task-due {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 4px;
  background-color: #f3f4f6;
  color: #374151;
}

.task-item--overdue .task-due {
  background-color: #fee2e2;
  color: #dc2626;
}

.dropdown-footer {
  padding: 12px;
  border-top: 1px solid #e5e7eb;
}

.view-all-btn {
  width: 100%;
  padding: 10px;
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.view-all-btn:hover {
  background-color: #2563eb;
}
</style>
