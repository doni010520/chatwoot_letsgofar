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
const showMobileSearch = ref(false);

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

const toggleMobileSearch = () => {
  showMobileSearch.value = !showMobileSearch.value;
  if (!showMobileSearch.value) {
    searchInputValue.value = '';
    onFilterChange({ q: '' });
  }
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
    <!-- Header Principal -->
    <header
      class="sticky top-0 z-10 border-b bg-n-surface-1 border-n-weak"
    >
      <!-- Linha principal do header -->
      <div class="flex items-center justify-between gap-2 px-4 py-2 sm:px-6 sm:py-3">
        <!-- Lado esquerdo: Título + Tabs -->
        <div class="flex items-center gap-2 sm:gap-4 min-w-0">
          <h1 class="text-base font-semibold text-n-slate-12 whitespace-nowrap sm:text-lg">
            Tarefas
          </h1>

          <!-- View Tabs - Desktop -->
          <div class="hidden md:flex items-center gap-1 p-1 rounded-lg bg-n-alpha-1">
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
              <span>{{ tab.label }}</span>
            </button>
          </div>

          <!-- View Tabs - Mobile (icons only) -->
          <div class="flex md:hidden items-center gap-0.5 p-0.5 rounded-lg bg-n-alpha-1">
            <button
              v-for="tab in viewTabs"
              :key="tab.key"
              type="button"
              class="flex items-center justify-center p-1.5 rounded-md transition-colors"
              :class="[
                currentView === tab.key
                  ? 'bg-n-solid-3 text-n-slate-12'
                  : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2',
              ]"
              :title="tab.label"
              @click="switchView(tab)"
            >
              <span :class="tab.icon" class="size-4" />
            </button>
          </div>
        </div>

        <!-- Lado direito: Ações -->
        <div class="flex items-center gap-2">
          <!-- Busca - Desktop -->
          <div class="relative hidden sm:block">
            <span
              class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-n-slate-10"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8"/>
                <path d="m21 21-4.3-4.3"/>
              </svg>
            </span>
            <input
              type="text"
              placeholder="Buscar tarefas..."
              class="pl-9 pr-3 py-1.5 w-40 lg:w-56 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand focus:border-transparent"
              :value="searchInputValue"
              @input="onSearchInput"
            />
          </div>

          <!-- Botão de busca - Mobile -->
          <button
            type="button"
            class="sm:hidden flex items-center justify-center p-2 rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 transition-colors"
            :class="{ '!bg-n-brand !text-white': showMobileSearch || searchInputValue }"
            @click="toggleMobileSearch"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="8"/>
              <path d="m21 21-4.3-4.3"/>
            </svg>
          </button>

          <!-- Botão de filtros -->
          <Button
            icon="i-lucide-filter"
            color="slate"
            size="sm"
            :class="{ '!bg-n-brand !text-white': hasActiveFilters }"
            @click="toggleFilters"
          >
            <span class="hidden sm:inline">Filtros</span>
          </Button>

          <!-- Botão de criar -->
          <Button
            icon="i-lucide-plus"
            color="blue"
            size="sm"
            @click="openCreateModal"
          >
            <span class="hidden sm:inline">Nova Tarefa</span>
          </Button>
        </div>
      </div>

      <!-- Barra de busca mobile (expansível) -->
      <div
        v-if="showMobileSearch"
        class="sm:hidden px-4 pb-2"
      >
        <div class="relative">
          <span
            class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-n-slate-10"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="8"/>
              <path d="m21 21-4.3-4.3"/>
            </svg>
          </span>
          <input
            type="text"
            placeholder="Buscar tarefas..."
            class="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand focus:border-transparent"
            :value="searchInputValue"
            @input="onSearchInput"
            autofocus
          />
        </div>
      </div>
    </header>

    <!-- Main Content Area -->
    <div class="flex flex-1 min-h-0 overflow-hidden">
      <!-- Stats Sidebar (apenas na view de lista e em desktop) -->
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

      <!-- Conteúdo Principal - Renderiza componente baseado na view atual -->
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
