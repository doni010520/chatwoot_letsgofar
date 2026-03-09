<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TaskFilters from './components/TaskFilters.vue';
import TaskStats from './components/TaskStats.vue';
import TaskModal from './components/TaskModal.vue';

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
  { key: 'list', label: 'TASKS.VIEWS.LIST', icon: 'i-lucide-list', route: 'tasks_list' },
  { key: 'calendar', label: 'TASKS.VIEWS.CALENDAR', icon: 'i-lucide-calendar', route: 'tasks_calendar' },
  { key: 'kanban', label: 'TASKS.VIEWS.KANBAN', icon: 'i-lucide-kanban', route: 'tasks_kanban' },
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

const onTaskCreated = async () => {
  closeCreateModal();
  
  // Recarregar dados
  if (currentView.value === 'kanban') {
    await store.dispatch('agentTasks/fetchKanban');
  } else {
    await store.dispatch('agentTasks/fetchTasks', { 
      page: store.state.agentTasks.pagination.currentPage 
    });
  }
  
  await store.dispatch('agentTasks/fetchStats');
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
      class="sticky top-0 z-10 flex items-center justify-between gap-4 px-6 py-3 border-b bg-n-surface-1 border-n-weak"
    >
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-semibold text-n-slate-12">
          {{ t('TASKS.TITLE') }}
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
            <span>{{ t(tab.label) }}</span>
          </button>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <!-- Busca rápida -->
        <div class="relative">
          <span
            class="absolute left-3 top-1/2 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10"
          />
          <input
            type="text"
            :placeholder="t('TASKS.SEARCH_PLACEHOLDER')"
            class="pl-9 pr-3 py-1.5 w-64 text-sm rounded-lg border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand"
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
          {{ t('TASKS.FILTERS.TITLE') }}
        </Button>

        <!-- Botão de criar -->
        <Button
          icon="i-lucide-plus"
          color="blue"
          size="sm"
          @click="openCreateModal"
        >
          {{ t('TASKS.NEW_TASK') }}
        </Button>
      </div>
    </header>

    <!-- Main Content Area -->
    <div class="flex flex-1 min-h-0 overflow-hidden">
      <!-- Stats Sidebar (apenas na view de lista) -->
      <aside
        v-if="currentView === 'list'"
        class="flex-shrink-0 w-56 overflow-y-auto border-r border-n-weak bg-n-surface-1"
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
        <router-view />
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
