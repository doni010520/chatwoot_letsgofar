<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import TaskFilters from './components/TaskFilters.vue';
import TaskStats from './components/TaskStats.vue';
import TaskModal from './components/TaskModal.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();

// Estado local
const showCreateModal = ref(false);
const showFiltersPanel = ref(false);

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
const viewTabs = computed(() => [
  {
    key: 'list',
    label: t('TASKS.VIEWS.LIST'),
    icon: 'i-lucide-list',
    route: 'tasks_list',
  },
  {
    key: 'calendar',
    label: t('TASKS.VIEWS.CALENDAR'),
    icon: 'i-lucide-calendar',
    route: 'tasks_calendar',
  },
  {
    key: 'kanban',
    label: t('TASKS.VIEWS.KANBAN'),
    icon: 'i-lucide-kanban',
    route: 'tasks_kanban',
  },
]);

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

const onTaskCreated = task => {
  closeCreateModal();
  if (currentView.value === 'kanban') {
    store.dispatch('agentTasks/fetchKanban');
  } else {
    store.dispatch('agentTasks/fetchTasks');
  }
};

const onFilterChange = newFilters => {
  store.dispatch('agentTasks/setFilters', newFilters);
};

const resetFilters = () => {
  store.dispatch('agentTasks/resetFilters');
};

// Carregar dados iniciais
onMounted(() => {
  store.dispatch('agentTasks/fetchStats');
});
</script>

<template>
  <div class="flex flex-col h-full bg-n-background">
    <!-- Header -->
    <header class="flex items-center justify-between px-4 py-3 border-b border-n-weak">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-semibold text-n-slate-12">
          {{ t('TASKS.TITLE') }}
        </h1>

        <!-- View Tabs -->
        <div class="flex items-center gap-1 p-1 rounded-lg bg-n-alpha-1">
          <button
            v-for="tab in viewTabs"
            :key="tab.key"
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
      </div>

      <div class="flex items-center gap-2">
        <!-- Busca rápida -->
        <div class="relative">
          <span class="absolute left-3 top-1/2 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10" />
          <input
            type="text"
            :placeholder="t('TASKS.SEARCH_PLACEHOLDER')"
            class="pl-9 pr-3 py-1.5 w-64 text-sm rounded-lg border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand"
            :value="filters.q"
            @input="e => onFilterChange({ q: e.target.value })"
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
          <span v-if="hasActiveFilters" class="ml-1 px-1.5 py-0.5 text-xs rounded-full bg-white/20">
            !
          </span>
        </Button>

        <!-- Botão de criar -->
        <Button
          icon="i-lucide-plus"
          color="primary"
          size="sm"
          @click="openCreateModal"
        >
          {{ t('TASKS.NEW_TASK') }}
        </Button>
      </div>
    </header>

    <!-- Main Content -->
    <div class="flex flex-1 overflow-hidden">
      <!-- Sidebar de Stats (opcional) -->
      <aside
        v-if="currentView === 'list'"
        class="w-56 flex-shrink-0 border-r border-n-weak overflow-y-auto"
      >
        <TaskStats :stats="stats" @filter-click="onFilterChange" />
      </aside>

      <!-- Painel de Filtros (colapsável) -->
      <aside
        v-if="showFiltersPanel"
        class="w-72 flex-shrink-0 border-r border-n-weak overflow-y-auto bg-n-alpha-1"
      >
        <TaskFilters
          :filters="filters"
          @change="onFilterChange"
          @reset="resetFilters"
          @close="toggleFilters"
        />
      </aside>

      <!-- Conteúdo Principal (router-view) -->
      <main class="flex-1 overflow-hidden">
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
