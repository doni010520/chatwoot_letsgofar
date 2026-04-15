<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TaskDetailPanel from './TaskDetailPanel.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const { t } = useI18n();

// ---------------------------------------------------------------------------
// Local state
// ---------------------------------------------------------------------------
const selectedTaskId = ref(null);
const searchQuery = ref('');
const statusFilter = ref('');
const priorityFilter = ref('');
const assigneeFilter = ref('');
const sortField = ref('due_date');
const sortDirection = ref('asc');
const selectedItems = ref([]);
const currentPage = ref(1);
const perPage = ref(25);
const openDropdown = ref(null);
const searchTimeout = ref(null);

// ---------------------------------------------------------------------------
// Store getters
// ---------------------------------------------------------------------------
const tasks = computed(() => store.getters['agentTasks/getTasks']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const pagination = computed(() => store.getters['agentTasks/getPagination']);
const filters = computed(() => store.getters['agentTasks/getFilters']);
const agents = computed(() => store.getters['agents/getAgents'] || []);

const selectedTask = computed(() => {
  if (!selectedTaskId.value) return null;
  return store.getters['agentTasks/getCurrentTask'];
});

// ---------------------------------------------------------------------------
// Status / Priority configs
// ---------------------------------------------------------------------------
const statusConfig = {
  pending: { label: 'Pendente', bg: 'bg-n-slate-3', text: 'text-n-slate-11', icon: 'i-lucide-circle' },
  in_progress: { label: 'Em andamento', bg: 'bg-blue-3', text: 'text-blue-11', icon: 'i-lucide-loader' },
  completed: { label: 'Concluida', bg: 'bg-green-3', text: 'text-green-11', icon: 'i-lucide-check-circle' },
  cancelled: { label: 'Cancelada', bg: 'bg-n-slate-3', text: 'text-n-slate-9', icon: 'i-lucide-x-circle' },
};

const priorityConfig = {
  urgent: { label: 'Urgente', bg: 'bg-ruby-3', text: 'text-ruby-11', icon: 'i-lucide-alert-circle' },
  high: { label: 'Alta', bg: 'bg-amber-3', text: 'text-amber-11', icon: 'i-lucide-arrow-up' },
  medium: { label: 'Media', bg: 'bg-blue-3', text: 'text-blue-11', icon: 'i-lucide-minus' },
  low: { label: 'Baixa', bg: 'bg-teal-3', text: 'text-teal-11', icon: 'i-lucide-arrow-down' },
};

const statusOptions = [
  { value: '', label: 'Todos os status' },
  { value: 'active', label: 'Ativos' },
  { value: 'pending', label: 'Pendente' },
  { value: 'in_progress', label: 'Em andamento' },
  { value: 'completed', label: 'Concluida' },
  { value: 'cancelled', label: 'Cancelada' },
];

const priorityOptions = [
  { value: '', label: 'Todas prioridades' },
  { value: 'urgent', label: 'Urgente' },
  { value: 'high', label: 'Alta' },
  { value: 'medium', label: 'Media' },
  { value: 'low', label: 'Baixa' },
];

// ---------------------------------------------------------------------------
// Filtering, sorting, pagination (client-side on the already-fetched page)
// ---------------------------------------------------------------------------
const filteredTasks = computed(() => {
  let items = [...tasks.value];

  // Text search
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    items = items.filter(task => {
      return (
        (task.title && task.title.toLowerCase().includes(q)) ||
        (task.description && task.description.toLowerCase().includes(q))
      );
    });
  }

  // Status filter (local – the store filter already applies server-side, but we
  // also allow a quick client-side refinement)
  if (statusFilter.value) {
    if (statusFilter.value === 'active') {
      items = items.filter(task => ['pending', 'in_progress'].includes(task.status));
    } else {
      items = items.filter(task => task.status === statusFilter.value);
    }
  }

  // Priority filter
  if (priorityFilter.value) {
    items = items.filter(task => task.priority === priorityFilter.value);
  }

  // Assignee filter
  if (assigneeFilter.value) {
    const id = parseInt(assigneeFilter.value);
    if (assigneeFilter.value === 'unassigned') {
      items = items.filter(task => !task.assigned_to);
    } else {
      items = items.filter(task => task.assigned_to?.id === id);
    }
  }

  // Sorting
  items.sort((a, b) => {
    let aVal, bVal;
    switch (sortField.value) {
      case 'title':
        aVal = (a.title || '').toLowerCase();
        bVal = (b.title || '').toLowerCase();
        break;
      case 'status':
        aVal = a.status || '';
        bVal = b.status || '';
        break;
      case 'priority': {
        const order = { urgent: 0, high: 1, medium: 2, low: 3 };
        aVal = order[a.priority] ?? 9;
        bVal = order[b.priority] ?? 9;
        break;
      }
      case 'due_date':
        aVal = a.due_date ? new Date(a.due_date).getTime() : Infinity;
        bVal = b.due_date ? new Date(b.due_date).getTime() : Infinity;
        break;
      case 'assignee':
        aVal = (a.assigned_to?.name || '').toLowerCase();
        bVal = (b.assigned_to?.name || '').toLowerCase();
        break;
      case 'contact':
        aVal = (a.contact?.name || '').toLowerCase();
        bVal = (b.contact?.name || '').toLowerCase();
        break;
      default:
        return 0;
    }
    if (aVal < bVal) return sortDirection.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortDirection.value === 'asc' ? 1 : -1;
    return 0;
  });

  return items;
});

const totalFilteredCount = computed(() => filteredTasks.value.length);

const totalPages = computed(() => Math.ceil(totalFilteredCount.value / perPage.value) || 1);

const startIndex = computed(() => (currentPage.value - 1) * perPage.value);

const endIndex = computed(() => Math.min(currentPage.value * perPage.value, totalFilteredCount.value));

const paginatedTasks = computed(() => {
  return filteredTasks.value.slice(startIndex.value, startIndex.value + perPage.value);
});

const hasFilters = computed(() => {
  return searchQuery.value || statusFilter.value || priorityFilter.value || assigneeFilter.value;
});

// ---------------------------------------------------------------------------
// Selection helpers
// ---------------------------------------------------------------------------
const isAllSelected = computed(() => {
  return paginatedTasks.value.length > 0 &&
    paginatedTasks.value.every(task => selectedItems.value.includes(task.id));
});

const isIndeterminate = computed(() => {
  const count = paginatedTasks.value.filter(task => selectedItems.value.includes(task.id)).length;
  return count > 0 && count < paginatedTasks.value.length;
});

// ---------------------------------------------------------------------------
// Date helpers
// ---------------------------------------------------------------------------
const parseDueDate = (dueDateStr) => {
  if (!dueDateStr) return null;
  const parts = dueDateStr.split('-');
  return new Date(parts[0], parts[1] - 1, parts[2]);
};

const isOverdue = (task) => {
  if (!task.due_date || task.status === 'completed' || task.status === 'cancelled') return false;
  const dueDate = parseDueDate(task.due_date);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return dueDate < today;
};

const isDueToday = (task) => {
  if (!task.due_date || task.status === 'completed' || task.status === 'cancelled') return false;
  const dueDate = parseDueDate(task.due_date);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return dueDate.toDateString() === today.toDateString();
};

const isOnTrack = (task) => {
  if (!task.due_date || task.status === 'completed' || task.status === 'cancelled') return false;
  return !isOverdue(task) && !isDueToday(task);
};

const formatDueDate = (task) => {
  if (!task.due_date) return '-';
  const dueDate = parseDueDate(task.due_date);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  if (dueDate.toDateString() === today.toDateString()) return 'Hoje';
  if (dueDate.toDateString() === tomorrow.toDateString()) return 'Amanha';

  const diffDays = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));
  if (diffDays < 0) {
    return `${Math.abs(diffDays)}d atrasada`;
  }

  return dueDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
};

const dueDateClass = (task) => {
  if (!task.due_date) return 'text-n-slate-9';
  if (task.status === 'completed' || task.status === 'cancelled') return 'text-n-slate-9';
  if (isOverdue(task)) return 'text-ruby-11 font-semibold';
  if (isDueToday(task)) return 'text-amber-11 font-semibold';
  return 'text-n-slate-11';
};

// ---------------------------------------------------------------------------
// Row styling
// ---------------------------------------------------------------------------
const rowBorderClass = (task) => {
  if (task.status === 'completed') return 'border-l-n-slate-7';
  if (task.status === 'cancelled') return 'border-l-n-slate-5';
  if (isOverdue(task)) return 'border-l-ruby-9';
  if (isDueToday(task)) return 'border-l-amber-9';
  if (isOnTrack(task)) return 'border-l-teal-9';
  return 'border-l-n-slate-4';
};

const rowOpacityClass = (task) => {
  if (task.status === 'completed' || task.status === 'cancelled') return 'opacity-55';
  return '';
};

// ---------------------------------------------------------------------------
// Checklist
// ---------------------------------------------------------------------------
const checklistProgress = (task) => {
  if (!task.items_count || task.items_count === 0) return null;
  return `${task.items_completed_count || 0}/${task.items_count}`;
};

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------
const loadTasks = (page = 1) => {
  store.dispatch('agentTasks/fetchTasks', { page });
};

const selectTask = async (task) => {
  selectedTaskId.value = task.id;
  await store.dispatch('agentTasks/fetchTask', task.id);
};

const closeDetailPanel = () => {
  selectedTaskId.value = null;
  store.dispatch('agentTasks/clearCurrentTask');
};

const onTaskUpdated = () => {
  loadTasks(pagination.value.currentPage);
};

const onTaskDeleted = () => {
  closeDetailPanel();
  loadTasks(pagination.value.currentPage);
};

const onTaskComplete = async (task) => {
  try {
    await store.dispatch('agentTasks/completeTask', task.id);
    loadTasks(pagination.value.currentPage);
    store.dispatch('agentTasks/fetchStats');
  } catch (error) {
    console.error('Error completing task:', error);
  }
};

const onTaskCancel = async (task) => {
  try {
    await store.dispatch('agentTasks/cancelTask', task.id);
    loadTasks(pagination.value.currentPage);
    store.dispatch('agentTasks/fetchStats');
  } catch (error) {
    console.error('Error cancelling task:', error);
  }
};

const onTaskDelete = async (task) => {
  if (!confirm('Tem certeza que deseja excluir esta tarefa?')) return;
  try {
    await store.dispatch('agentTasks/deleteTask', task.id);
    loadTasks(pagination.value.currentPage);
    store.dispatch('agentTasks/fetchStats');
  } catch (error) {
    console.error('Error deleting task:', error);
  }
};

// ---------------------------------------------------------------------------
// Toolbar actions
// ---------------------------------------------------------------------------
const onSearchChange = () => {
  clearTimeout(searchTimeout.value);
  searchTimeout.value = setTimeout(() => {
    currentPage.value = 1;
  }, 300);
};

const clearFilters = () => {
  searchQuery.value = '';
  statusFilter.value = '';
  priorityFilter.value = '';
  assigneeFilter.value = '';
  currentPage.value = 1;
};

const handleSort = (field) => {
  if (sortField.value === field) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortField.value = field;
    sortDirection.value = 'asc';
  }
};

// ---------------------------------------------------------------------------
// Selection
// ---------------------------------------------------------------------------
const toggleSelect = (taskId) => {
  const idx = selectedItems.value.indexOf(taskId);
  if (idx > -1) {
    selectedItems.value.splice(idx, 1);
  } else {
    selectedItems.value.push(taskId);
  }
};

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedItems.value = selectedItems.value.filter(
      id => !paginatedTasks.value.find(task => task.id === id)
    );
  } else {
    const newIds = paginatedTasks.value.map(task => task.id);
    selectedItems.value = [...new Set([...selectedItems.value, ...newIds])];
  }
};

// ---------------------------------------------------------------------------
// Dropdown
// ---------------------------------------------------------------------------
const toggleDropdown = (taskId) => {
  openDropdown.value = openDropdown.value === taskId ? null : taskId;
};

const closeDropdown = (e) => {
  if (!e.target.closest('.action-dropdown')) {
    openDropdown.value = null;
  }
};

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------
const loadPage = (page) => {
  if (page < 1 || page > totalPages.value) return;
  currentPage.value = page;
  // Also fetch from server if the server paginates
  loadTasks(page);
};

const changePerPage = () => {
  currentPage.value = 1;
  loadTasks(1);
};

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------
onMounted(() => {
  loadTasks();
  document.addEventListener('click', closeDropdown);
});

onBeforeUnmount(() => {
  document.removeEventListener('click', closeDropdown);
});

watch(filters, () => {
  loadTasks(1);
  currentPage.value = 1;
}, { deep: true });
</script>

<template>
  <div class="flex h-full">
    <!-- Task Table -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Loading -->
      <div v-if="uiFlags.isLoading" class="flex items-center justify-center h-full">
        <Spinner size="large" />
      </div>

      <template v-else>
        <!-- ============================================================ -->
        <!-- TOOLBAR                                                       -->
        <!-- ============================================================ -->
        <div class="task-toolbar">
          <div class="task-toolbar__left">
            <!-- Search -->
            <div class="task-toolbar__search">
              <span class="i-lucide-search size-4 text-n-slate-9 flex-shrink-0" />
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Buscar por titulo ou descricao..."
                @input="onSearchChange"
              />
            </div>
            <!-- Counter -->
            <span class="task-toolbar__count">
              {{ totalFilteredCount }} de {{ tasks.length }} tarefas
            </span>
          </div>

          <div class="task-toolbar__right">
            <!-- Status -->
            <select
              v-model="statusFilter"
              class="task-toolbar__filter"
              @change="currentPage = 1"
            >
              <option
                v-for="opt in statusOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </option>
            </select>

            <!-- Priority -->
            <select
              v-model="priorityFilter"
              class="task-toolbar__filter"
              @change="currentPage = 1"
            >
              <option
                v-for="opt in priorityOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </option>
            </select>

            <!-- Assignee -->
            <select
              v-model="assigneeFilter"
              class="task-toolbar__filter"
              @change="currentPage = 1"
            >
              <option value="">Todos responsaveis</option>
              <option value="unassigned">Nao atribuido</option>
              <option
                v-for="agent in agents"
                :key="agent.id"
                :value="agent.id"
              >
                {{ agent.name }}
              </option>
            </select>

            <!-- Clear filters -->
            <button
              v-if="hasFilters"
              class="task-toolbar__clear"
              @click="clearFilters"
            >
              Limpar filtros
            </button>
          </div>
        </div>

        <!-- ============================================================ -->
        <!-- TABLE                                                         -->
        <!-- ============================================================ -->
        <div class="task-table-container">
          <table class="task-table">
            <thead>
              <tr>
                <!-- Checkbox -->
                <th class="task-table__th task-table__th--checkbox">
                  <input
                    type="checkbox"
                    :checked="isAllSelected"
                    :indeterminate.prop="isIndeterminate"
                    @change="toggleSelectAll"
                  />
                </th>
                <!-- Title -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('title')"
                >
                  <span>Titulo</span>
                  <span v-if="sortField === 'title'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Status -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('status')"
                >
                  <span>Status</span>
                  <span v-if="sortField === 'status'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Priority -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('priority')"
                >
                  <span>Prioridade</span>
                  <span v-if="sortField === 'priority'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Due date -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('due_date')"
                >
                  <span>Vencimento</span>
                  <span v-if="sortField === 'due_date'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Assignee -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('assignee')"
                >
                  <span>Responsavel</span>
                  <span v-if="sortField === 'assignee'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Contact -->
                <th
                  class="task-table__th task-table__th--sortable"
                  @click="handleSort('contact')"
                >
                  <span>Contato</span>
                  <span v-if="sortField === 'contact'" class="sort-icon">
                    {{ sortDirection === 'asc' ? '\u2191' : '\u2193' }}
                  </span>
                </th>
                <!-- Actions -->
                <th class="task-table__th task-table__th--actions">Acoes</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="task in paginatedTasks"
                :key="task.id"
                class="task-table__row border-l-4"
                :class="[
                  rowBorderClass(task),
                  rowOpacityClass(task),
                  selectedItems.includes(task.id) ? 'task-table__row--selected' : '',
                  selectedTaskId === task.id ? 'task-table__row--active' : '',
                ]"
                @click="selectTask(task)"
              >
                <!-- Checkbox -->
                <td class="task-table__td task-table__td--checkbox" @click.stop>
                  <input
                    type="checkbox"
                    :checked="selectedItems.includes(task.id)"
                    @change="toggleSelect(task.id)"
                  />
                </td>

                <!-- Title -->
                <td class="task-table__td task-table__td--title">
                  <div class="flex flex-col gap-0.5">
                    <span
                      class="font-medium text-sm truncate max-w-[280px]"
                      :class="task.status === 'completed' ? 'line-through text-n-slate-10' : 'text-n-slate-12'"
                      :title="task.title"
                    >
                      {{ task.title }}
                    </span>
                    <div class="flex items-center gap-2">
                      <span
                        v-if="checklistProgress(task)"
                        class="inline-flex items-center gap-1 text-xs text-n-slate-10"
                      >
                        <span class="i-lucide-check-square size-3" />
                        {{ checklistProgress(task) }}
                      </span>
                      <span
                        v-if="task.comments_count > 0"
                        class="inline-flex items-center gap-1 text-xs text-n-slate-10"
                      >
                        <span class="i-lucide-message-square size-3" />
                        {{ task.comments_count }}
                      </span>
                      <span
                        v-if="task.files_count > 0"
                        class="inline-flex items-center gap-1 text-xs text-n-slate-10"
                      >
                        <span class="i-lucide-paperclip size-3" />
                        {{ task.files_count }}
                      </span>
                    </div>
                  </div>
                </td>

                <!-- Status -->
                <td class="task-table__td">
                  <span
                    class="inline-flex items-center gap-1.5 px-2 py-1 text-xs font-medium rounded-full whitespace-nowrap"
                    :class="[
                      (statusConfig[task.status] || statusConfig.pending).bg,
                      (statusConfig[task.status] || statusConfig.pending).text,
                    ]"
                  >
                    <span
                      :class="(statusConfig[task.status] || statusConfig.pending).icon"
                      class="size-3"
                    />
                    {{ (statusConfig[task.status] || statusConfig.pending).label }}
                  </span>
                </td>

                <!-- Priority -->
                <td class="task-table__td">
                  <span
                    class="inline-flex items-center gap-1.5 px-2 py-1 text-xs font-medium rounded-full whitespace-nowrap"
                    :class="[
                      (priorityConfig[task.priority] || priorityConfig.medium).bg,
                      (priorityConfig[task.priority] || priorityConfig.medium).text,
                    ]"
                  >
                    <span
                      :class="(priorityConfig[task.priority] || priorityConfig.medium).icon"
                      class="size-3"
                    />
                    {{ (priorityConfig[task.priority] || priorityConfig.medium).label }}
                  </span>
                </td>

                <!-- Due date -->
                <td class="task-table__td task-table__td--date">
                  <span
                    class="inline-flex items-center gap-1.5 text-xs whitespace-nowrap"
                    :class="dueDateClass(task)"
                  >
                    <span class="i-lucide-calendar size-3" />
                    {{ formatDueDate(task) }}
                    <span v-if="task.due_time" class="text-n-slate-10">
                      {{ task.due_time }}
                    </span>
                  </span>
                </td>

                <!-- Assignee -->
                <td class="task-table__td">
                  <div v-if="task.assigned_to" class="flex items-center gap-2">
                    <Avatar
                      :name="task.assigned_to.name"
                      :src="task.assigned_to.avatar_url"
                      size="24px"
                    />
                    <span class="text-xs text-n-slate-11 truncate max-w-[100px]">
                      {{ task.assigned_to.name }}
                    </span>
                  </div>
                  <span v-else class="text-xs text-n-slate-9 italic">
                    Nao atribuido
                  </span>
                </td>

                <!-- Contact -->
                <td class="task-table__td">
                  <span
                    v-if="task.contact"
                    class="inline-flex items-center gap-1.5 text-xs text-n-slate-11"
                  >
                    <span class="i-lucide-user size-3 text-n-slate-9" />
                    <span class="truncate max-w-[100px]">{{ task.contact.name }}</span>
                  </span>
                  <span v-else class="text-xs text-n-slate-9">-</span>
                </td>

                <!-- Actions -->
                <td class="task-table__td task-table__td--actions" @click.stop>
                  <div class="actions-menu">
                    <!-- View -->
                    <button
                      class="action-btn"
                      title="Visualizar"
                      @click="selectTask(task)"
                    >
                      <span class="i-lucide-eye size-3.5" />
                    </button>

                    <!-- Complete -->
                    <button
                      v-if="task.status !== 'completed' && task.status !== 'cancelled'"
                      class="action-btn action-btn--success"
                      title="Marcar como concluida"
                      @click="onTaskComplete(task)"
                    >
                      <span class="i-lucide-check size-3.5" />
                    </button>

                    <!-- Dropdown -->
                    <div class="action-dropdown">
                      <button
                        class="action-btn"
                        title="Mais opcoes"
                        @click="toggleDropdown(task.id)"
                      >
                        <span class="i-lucide-more-horizontal size-3.5" />
                      </button>
                      <div
                        v-if="openDropdown === task.id"
                        class="dropdown-menu"
                      >
                        <button @click="selectTask(task)">
                          <span class="i-lucide-pencil size-3.5" />
                          Editar
                        </button>
                        <button
                          v-if="task.status !== 'cancelled'"
                          @click="onTaskCancel(task)"
                        >
                          <span class="i-lucide-ban size-3.5" />
                          Cancelar
                        </button>
                        <button
                          class="text-ruby-11 hover:!bg-ruby-3"
                          @click="onTaskDelete(task)"
                        >
                          <span class="i-lucide-trash-2 size-3.5" />
                          Excluir
                        </button>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty state -->
              <tr v-if="paginatedTasks.length === 0">
                <td colspan="8" class="task-table__empty">
                  <div class="empty-state">
                    <span class="i-lucide-inbox size-10 text-n-slate-7" />
                    <h3 class="text-base font-medium text-n-slate-11">
                      {{ t('TASKS.EMPTY_STATE.TITLE') }}
                    </h3>
                    <p class="text-sm text-n-slate-9">
                      {{ hasFilters ? 'Nenhuma tarefa encontrada com os filtros aplicados.' : t('TASKS.EMPTY_STATE.DESCRIPTION') }}
                    </p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- ============================================================ -->
        <!-- PAGINATION                                                    -->
        <!-- ============================================================ -->
        <div v-if="totalFilteredCount > 0" class="task-pagination">
          <div class="task-pagination__info">
            Mostrando {{ startIndex + 1 }} - {{ endIndex }} de {{ totalFilteredCount }}
          </div>
          <div class="task-pagination__controls">
            <select
              v-model="perPage"
              class="task-pagination__per-page"
              @change="changePerPage"
            >
              <option :value="10">10 por pagina</option>
              <option :value="25">25 por pagina</option>
              <option :value="50">50 por pagina</option>
              <option :value="100">100 por pagina</option>
            </select>

            <div class="task-pagination__buttons">
              <button
                class="pagination-btn"
                :disabled="currentPage === 1"
                title="Primeira pagina"
                @click="loadPage(1)"
              >
                <span class="i-lucide-chevrons-left size-3.5" />
              </button>
              <button
                class="pagination-btn"
                :disabled="currentPage === 1"
                title="Pagina anterior"
                @click="loadPage(currentPage - 1)"
              >
                <span class="i-lucide-chevron-left size-3.5" />
              </button>
              <span class="pagination-info">
                Pagina {{ currentPage }} de {{ totalPages }}
              </span>
              <button
                class="pagination-btn"
                :disabled="currentPage === totalPages"
                title="Proxima pagina"
                @click="loadPage(currentPage + 1)"
              >
                <span class="i-lucide-chevron-right size-3.5" />
              </button>
              <button
                class="pagination-btn"
                :disabled="currentPage === totalPages"
                title="Ultima pagina"
                @click="loadPage(totalPages)"
              >
                <span class="i-lucide-chevrons-right size-3.5" />
              </button>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- ================================================================ -->
    <!-- DETAIL PANEL (unchanged integration)                              -->
    <!-- ================================================================ -->
    <TaskDetailPanel
      v-if="selectedTask"
      :task="selectedTask"
      @close="closeDetailPanel"
      @updated="onTaskUpdated"
      @deleted="onTaskDeleted"
    />
  </div>
</template>

<style lang="scss" scoped>
/* ====================================================================== */
/* TOOLBAR                                                                 */
/* ====================================================================== */
.task-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding: 12px 20px;
  border-bottom: 1px solid var(--s-100);
  background: var(--white);

  &__left {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  &__search {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 7px 12px;
    background: var(--s-50);
    border: 1px solid var(--s-200);
    border-radius: 8px;
    min-width: 280px;

    input {
      flex: 1;
      border: none;
      background: none;
      font-size: 13px;
      color: var(--s-800);
      outline: none;

      &::placeholder {
        color: var(--s-400);
      }
    }
  }

  &__count {
    font-size: 12px;
    color: var(--s-500);
    white-space: nowrap;
  }

  &__right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__filter {
    padding: 7px 10px;
    border: 1px solid var(--s-200);
    border-radius: 8px;
    font-size: 12px;
    background: var(--white);
    color: var(--s-700);
    cursor: pointer;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }
  }

  &__clear {
    padding: 7px 12px;
    border: none;
    background: none;
    color: var(--w-500);
    font-size: 12px;
    font-weight: 500;
    cursor: pointer;
    white-space: nowrap;

    &:hover {
      text-decoration: underline;
    }
  }
}

/* ====================================================================== */
/* TABLE                                                                   */
/* ====================================================================== */
.task-table-container {
  flex: 1;
  overflow: auto;
}

.task-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 960px;

  &__th {
    position: sticky;
    top: 0;
    z-index: 10;
    padding: 10px 14px;
    text-align: left;
    font-size: 11px;
    font-weight: 600;
    color: var(--s-500);
    text-transform: uppercase;
    letter-spacing: 0.04em;
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
      padding-left: 20px;
    }

    &--actions {
      width: 120px;
      text-align: center;
    }

    .sort-icon {
      margin-left: 3px;
      color: var(--w-500);
      font-weight: 700;
    }
  }

  &__row {
    cursor: pointer;
    transition: background-color 0.15s;

    &:hover {
      background: var(--s-25);
    }

    &--selected {
      background: rgba(59, 130, 246, 0.06) !important;
    }

    &--active {
      background: rgba(59, 130, 246, 0.08) !important;
      box-shadow: inset 0 0 0 1px rgba(59, 130, 246, 0.15);
    }
  }

  &__td {
    padding: 10px 14px;
    border-bottom: 1px solid var(--s-100);
    font-size: 13px;
    color: var(--s-700);
    vertical-align: middle;

    &--checkbox {
      width: 40px;
      padding-left: 20px;
    }

    &--title {
      min-width: 200px;
      max-width: 300px;
    }

    &--date {
      white-space: nowrap;
    }

    &--actions {
      text-align: center;
    }
  }

  &__empty {
    padding: 60px 20px;
    text-align: center;

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
    }
  }
}

/* ====================================================================== */
/* ACTIONS                                                                 */
/* ====================================================================== */
.actions-menu {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 6px;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
  color: var(--s-500);

  &:hover {
    background: var(--s-100);
    color: var(--s-700);
  }

  &--success:hover {
    background: rgba(16, 185, 129, 0.12);
    color: #10b981;
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
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  z-index: 100;
  min-width: 160px;

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

    &:hover {
      background: var(--s-50);
    }
  }
}

/* ====================================================================== */
/* PAGINATION                                                              */
/* ====================================================================== */
.task-pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 20px;
  border-top: 1px solid var(--s-100);
  background: var(--s-25);

  &__info {
    font-size: 12px;
    color: var(--s-500);
  }

  &__controls {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  &__per-page {
    padding: 5px 8px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 12px;
    background: var(--white);
    cursor: pointer;
  }

  &__buttons {
    display: flex;
    align-items: center;
    gap: 4px;
  }
}

.pagination-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background: var(--white);
  cursor: pointer;
  color: var(--s-600);
  transition: all 0.15s;

  &:hover:not(:disabled) {
    background: var(--s-50);
    color: var(--s-800);
  }

  &:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
}

.pagination-info {
  font-size: 12px;
  color: var(--s-600);
  padding: 0 8px;
  white-space: nowrap;
}

/* ====================================================================== */
/* DARK MODE                                                               */
/* ====================================================================== */
.dark {
  .task-toolbar {
    background: var(--s-900);
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

      option {
        background: var(--s-900) !important;
        color: var(--s-200) !important;
      }
    }
  }

  .task-table {
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

  .action-btn {
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

  .task-pagination {
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
    }
  }
}
</style>
