<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import TaskCard from './TaskCard.vue';
import TaskDetailPanel from './TaskDetailPanel.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const selectedTaskId = ref(null);
const isInitialized = ref(false);
let debounceTimer = null;

// Getters
const tasks = computed(() => store.getters['agentTasks/getTasks']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const pagination = computed(() => store.getters['agentTasks/getPagination']);
const filters = computed(() => store.getters['agentTasks/getFilters']);

// Task selecionada
const selectedTask = computed(() => {
  if (!selectedTaskId.value) return null;
  return store.getters['agentTasks/getCurrentTask'];
});

// Métodos
const loadTasks = async (page = 1) => {
  try {
    await store.dispatch('agentTasks/fetchTasks', { page });
  } catch (error) {
    console.error('Error loading tasks:', error);
  }
};

// Debounced load para evitar múltiplas requisições
const debouncedLoadTasks = (page = 1) => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
  debounceTimer = setTimeout(() => {
    loadTasks(page);
  }, 150);
};

const selectTask = async task => {
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

const loadPage = page => {
  loadTasks(page);
};

// Carregar ao montar
onMounted(async () => {
  await loadTasks();
  setTimeout(() => {
    isInitialized.value = true;
  }, 200);
});

// Limpar timer ao desmontar
onBeforeUnmount(() => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
});

// Recarregar quando filtros mudarem
watch(
  filters,
  () => {
    if (isInitialized.value) {
      debouncedLoadTasks(1);
    }
  },
  { deep: true }
);
</script>

<template>
  <div class="flex h-full bg-n-alpha-1">
    <!-- Lista de Tarefas -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Loading -->
      <div v-if="uiFlags.isLoading && tasks.length === 0" class="flex items-center justify-center h-full">
        <Spinner size="large" />
      </div>

      <!-- Empty State -->
      <div 
        v-else-if="!uiFlags.isLoading && tasks.length === 0" 
        class="flex-1 flex items-center justify-center"
      >
        <div class="text-center px-8 py-16">
          <div class="size-20 rounded-2xl bg-n-alpha-3 flex items-center justify-center mx-auto mb-4">
            <span class="i-lucide-clipboard-list size-10 text-n-slate-8" />
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
            Nenhuma tarefa encontrada
          </h3>
          <p class="text-sm text-n-slate-10 max-w-sm">
            Crie sua primeira tarefa para começar a organizar seu trabalho.
          </p>
        </div>
      </div>

      <!-- Lista -->
      <div v-else class="flex-1 overflow-y-auto p-5">
        <div class="space-y-3 max-w-4xl">
          <TaskCard
            v-for="task in tasks"
            :key="task.id"
            :task="task"
            :is-selected="selectedTaskId === task.id"
            @click="selectTask(task)"
            @complete="store.dispatch('agentTasks/completeTask', task.id)"
          />
        </div>

        <!-- Paginação - visual melhorado -->
        <div
          v-if="pagination.totalPages > 1"
          class="flex items-center justify-center gap-3 mt-8 pb-6"
        >
          <button
            class="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-xl border border-n-weak bg-n-background hover:bg-n-alpha-2 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            :disabled="pagination.currentPage === 1"
            @click="loadPage(pagination.currentPage - 1)"
          >
            <span class="i-lucide-chevron-left size-4" />
            Anterior
          </button>

          <div class="flex items-center gap-2 px-4 py-2 rounded-xl bg-n-alpha-2">
            <span class="text-sm font-bold text-n-slate-12">{{ pagination.currentPage }}</span>
            <span class="text-sm text-n-slate-9">de</span>
            <span class="text-sm font-bold text-n-slate-12">{{ pagination.totalPages }}</span>
          </div>

          <button
            class="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-xl border border-n-weak bg-n-background hover:bg-n-alpha-2 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            :disabled="pagination.currentPage === pagination.totalPages"
            @click="loadPage(pagination.currentPage + 1)"
          >
            Próxima
            <span class="i-lucide-chevron-right size-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Painel de Detalhes -->
    <TaskDetailPanel
      v-if="selectedTask"
      :task="selectedTask"
      @close="closeDetailPanel"
      @updated="onTaskUpdated"
      @deleted="onTaskDeleted"
    />
  </div>
</template>
