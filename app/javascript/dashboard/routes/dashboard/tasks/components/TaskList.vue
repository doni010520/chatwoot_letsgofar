<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import TaskCard from './TaskCard.vue';
import TaskDetailPanel from './TaskDetailPanel.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EmptyState from 'dashboard/components-next/empty-state/EmptyState.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const selectedTaskId = ref(null);

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
const loadTasks = (page = 1) => {
  store.dispatch('agentTasks/fetchTasks', { page });
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
onMounted(() => {
  loadTasks();
});

// Recarregar quando filtros mudarem
watch(filters, () => {
  loadTasks(1);
}, { deep: true });
</script>

<template>
  <div class="flex h-full">
    <!-- Lista de Tarefas -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Loading -->
      <div v-if="uiFlags.isLoading" class="flex items-center justify-center h-full">
        <Spinner size="large" />
      </div>

      <!-- Empty State -->
      <EmptyState
        v-else-if="tasks.length === 0"
        :title="t('TASKS.EMPTY_STATE.TITLE')"
        :description="t('TASKS.EMPTY_STATE.DESCRIPTION')"
        icon="i-lucide-check-square"
      />

      <!-- Lista -->
      <div v-else class="flex-1 overflow-y-auto p-4">
        <div class="space-y-2">
          <TaskCard
            v-for="task in tasks"
            :key="task.id"
            :task="task"
            :is-selected="selectedTaskId === task.id"
            @click="selectTask(task)"
            @complete="store.dispatch('agentTasks/completeTask', task.id)"
          />
        </div>

        <!-- Paginação -->
        <div
          v-if="pagination.totalPages > 1"
          class="flex items-center justify-center gap-2 mt-6 pb-4"
        >
          <button
            class="px-3 py-1.5 text-sm rounded-lg border border-n-weak hover:bg-n-alpha-2 disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="pagination.currentPage === 1"
            @click="loadPage(pagination.currentPage - 1)"
          >
            {{ t('PAGINATION.PREVIOUS') }}
          </button>

          <span class="text-sm text-n-slate-11">
            {{ pagination.currentPage }} / {{ pagination.totalPages }}
          </span>

          <button
            class="px-3 py-1.5 text-sm rounded-lg border border-n-weak hover:bg-n-alpha-2 disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="pagination.currentPage === pagination.totalPages"
            @click="loadPage(pagination.currentPage + 1)"
          >
            {{ t('PAGINATION.NEXT') }}
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
