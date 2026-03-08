<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import TaskFilters from './components/TaskFilters.vue';
import TaskStats from './components/TaskStats.vue';
import TaskModal from './components/TaskModal.vue';
import TaskList from './components/TaskList.vue';
import TaskCalendar from './components/TaskCalendar.vue';
import TaskKanban from './components/TaskKanban.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

// Estado local
const showCreateModal = ref(false);
const showFiltersPanel = ref(false);
const searchInputValue = ref('');

// Getters da store
const stats = computed(() => store.getters['agentTasks/getStats']);
const filters = computed(() => store.getters['agentTasks/getFilters']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const hasActiveFilters = computed(() => store.getters['agentTasks/hasActiveFilters']);

// View atual baseada na rota
const currentView = computed(() => {
  if (route.name === 'tasks_calendar') return 'calendar';
  if (route.name === 'tasks_kanban') return 'kanban';
  return 'list';
});

// Tabs de navegação
const viewTabs = [
  { key: 'list', label: 'Lista', icon: 'i-lucide-list', route: 'tasks_list' },
  { key: 'calendar', label: 'Calendário', icon: 'i-lucide-calendar', route: 'tasks_calendar' },
  { key: 'kanban', label: 'Kanban', icon: 'i-lucide-kanban', route: 'tasks_kanban' },
];

// Métodos
const switchView = view => {
  router.push({ name: view.route });
};

const openCreateModal = () => {
  showCreateModal.value = true;
};

const closeCreateModal = () => {
  showCreateModal.value = false;
};

const toggleFilters = () => {
  showFiltersPanel.value = !showFiltersPanel.value;
};

const onTaskCreated = () => {
  closeCreateModal();
  if (currentView.value === 'kanban') {
    store.dispatch('agentTasks/fetchKanban');
  } else if (currentView.value === 'calendar') {
    // Reload calendar data
  } else {
    store.dispatch('agentTasks/fetchTasks');
  }
  store.dispatch('agentTasks/fetchStats');
};

const onFilterChange = newFilters => {
  store.dispatch('agentTasks/setFilters', newFilters);
};

const resetFilters = () => {
  store.dispatch('agentTasks/resetFilters');
  searchInputValue.value = '';
};

const onSearchInput = event => {
  const value = event.target.value;
  searchInputValue.value = value;
  onFilterChange({ q: value });
};

// Carregar dados iniciais
onMounted(() => {
  store.dispatch('agentTasks/fetchStats');
});

// Sync search input com filters
watch(
  () => filters.value.q,
  newVal => {
    if (searchInputValue.value !== newVal) {
      searchInputValue.value = newVal || '';
    }
  },
  { immediate: true }
);
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-surface-1"
  >
    <!-- Header -->
    <header
      class="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 px-4 py-3 border-b bg-n-surface-1 border-n-weak"
    >
      <!-- Lado esquerdo: Título + Tabs -->
      <div class="flex items-center gap-3">
        <h1 class="text-lg font-semibold text-n-slate-12">
          Tarefas
        </h1>

        <!-- View Tabs -->
        <div class="flex items-center gap-1 p-1 rounded-lg bg-n-alpha-1">
          <button
            v-for="tab in viewTabs"
            :key="tab.key"
            type="button"
            class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-md transition-colors"
            :class="[
              currentView === tab.key
                ? 'bg-n-solid-3 text-n-slate-12 font-medium'
                : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2',
            ]"
            @click="switchView(tab)"
          >
            <span :class="tab.icon" class="size-4" />
            <span class="hidden sm:inline">{{ tab.label }}</span>
          </button>
        </div>
      </div>

      <!-- Lado direito: Busca + Filtros + Criar (ALINHADOS) -->
      <div class="header-actions">
        <!-- Campo de busca -->
        <div class="search-box">
          <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8"/>
            <path d="m21 21-4.3-4.3"/>
          </svg>
          <input
            type="text"
            placeholder="Buscar..."
            class="search-input"
            :value="searchInputValue"
            @input="onSearchInput"
          />
        </div>

        <!-- Botão de filtros -->
        <Button
          icon="i-lucide-filter"
          color="slate"
          size="sm"
          :class="{ '!bg-n-brand !text-white': hasActiveFilters }"
          @click="toggleFilters"
        >
          Filtros
        </Button>

        <!-- Botão de criar -->
        <Button
          icon="i-lucide-plus"
          color="blue"
          size="sm"
          @click="openCreateModal"
        >
          Nova Tarefa
        </Button>
      </div>
    </header>

    <!-- Main Content Area -->
    <div class="flex flex-1 min-h-0 overflow-hidden">
      <!-- Stats Sidebar (apenas na view de lista) -->
      <aside
        v-if="currentView === 'list'"
        class="hidden lg:block flex-shrink-0 w-56 overflow-y-auto border-r border-n-weak bg-n-surface-1"
      >
        <TaskStats :stats="stats" @filter-click="onFilterChange" />
      </aside>

      <!-- Painel de Filtros (colapsável) -->
      <aside
        v-if="showFiltersPanel"
        class="flex-shrink-0 overflow-y-auto border-r w-72 border-n-weak bg-n-alpha-1"
      >
        <TaskFilters
          :filters="filters"
          @change="onFilterChange"
          @reset="resetFilters"
          @close="toggleFilters"
        />
      </aside>

      <!-- Conteúdo Principal -->
      <main class="flex-1 min-w-0 overflow-hidden">
        <TaskList v-if="currentView === 'list'" />
        <TaskCalendar v-else-if="currentView === 'calendar'" />
        <TaskKanban v-else-if="currentView === 'kanban'" />
      </main>
    </div>

    <!-- Modal de Criação -->
    <TaskModal
      v-if="showCreateModal"
      @close="closeCreateModal"
      @created="onTaskCreated"
    />
  </div>
</template>

<style scoped>
/* Container das ações do header - ALINHAMENTO VERTICAL */
.header-actions {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 8px;
  height: 36px; /* Altura fixa para garantir alinhamento */
}

/* Campo de busca */
.search-box {
  position: relative;
  display: flex;
  align-items: center;
  height: 36px;
}

.search-icon {
  position: absolute;
  left: 10px;
  width: 16px;
  height: 16px;
  color: #64748b;
  pointer-events: none;
}

.search-input {
  height: 36px;
  padding: 0 12px 0 34px;
  width: 140px;
  font-size: 14px;
  line-height: 36px;
  border-radius: 8px;
  border: 1px solid rgba(100, 116, 139, 0.4);
  background: rgba(30, 41, 59, 0.8);
  color: #f1f5f9;
}

.search-input::placeholder {
  color: #64748b;
}

.search-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.25);
}

/* Garantir que os botões do Chatwoot tenham a mesma altura */
.header-actions :deep(button) {
  height: 36px !important;
}
</style>
