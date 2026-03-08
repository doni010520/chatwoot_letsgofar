<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import TaskCard from './TaskCard.vue';
import TaskDetailPanel from './TaskDetailPanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const selectedTask = ref(null);
const isInitialized = ref(false);

// Debounce timer
let debounceTimer = null;

// Getters
const tasks = computed(() => store.getters['agentTasks/getTasks'] || []);
const pagination = computed(() => store.getters['agentTasks/getPagination']);
const filters = computed(() => store.getters['agentTasks/getFilters']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);

// Fetch tasks com debounce
const fetchTasks = (page = 1) => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
  debounceTimer = setTimeout(() => {
    store.dispatch('agentTasks/fetchTasks', { page });
  }, 150);
};

// Métodos
const onPageChange = page => {
  fetchTasks(page);
};

const openTaskDetails = task => {
  selectedTask.value = task;
};

const closeTaskDetails = () => {
  selectedTask.value = null;
};

const onTaskUpdated = () => {
  fetchTasks(pagination.value.currentPage);
  store.dispatch('agentTasks/fetchStats');
};

const onTaskDeleted = () => {
  closeTaskDetails();
  fetchTasks(pagination.value.currentPage);
  store.dispatch('agentTasks/fetchStats');
};

// Watch filters com debounce
watch(
  () => filters.value,
  () => {
    if (isInitialized.value) {
      fetchTasks(1);
    }
  },
  { deep: true }
);

// Carregar dados iniciais
onMounted(() => {
  // Pequeno delay para evitar race condition com outros componentes
  setTimeout(() => {
    isInitialized.value = true;
    fetchTasks();
  }, 200);
});

// Cleanup
onBeforeUnmount(() => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
});
</script>

<template>
  <div class="flex h-full">
    <!-- Lista principal -->
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Loading state -->
      <div v-if="uiFlags.isLoading && tasks.length === 0" class="flex items-center justify-center h-full">
        <div class="flex flex-col items-center gap-3">
          <span class="i-lucide-loader-2 size-8 text-n-brand animate-spin" />
          <span class="text-sm text-n-slate-11">Carregando tarefas...</span>
        </div>
      </div>

      <!-- Empty state -->
      <div 
        v-else-if="!uiFlags.isLoading && tasks.length === 0" 
        class="flex items-center justify-center h-full p-8"
      >
        <div class="text-center max-w-sm">
          <div class="size-20 rounded-2xl bg-gradient-to-br from-n-alpha-3 to-n-alpha-1 flex items-center justify-center mx-auto mb-4 border border-n-weak">
            <span class="i-lucide-inbox size-10 text-n-slate-9" />
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
            Nenhuma tarefa encontrada
          </h3>
          <p class="text-sm text-n-slate-10 mb-4">
            Crie sua primeira tarefa clicando no botão "Nova Tarefa" acima.
          </p>
        </div>
      </div>

      <!-- Lista de tarefas -->
      <div v-else class="flex-1 overflow-y-auto p-5">
        <div class="grid gap-3">
          <TaskCard
            v-for="task in tasks"
            :key="task.id"
            :task="task"
            @click="openTaskDetails(task)"
            @updated="onTaskUpdated"
          />
        </div>

        <!-- Paginação -->
        <div
          v-if="pagination.totalPages > 1"
          class="flex items-center justify-center gap-2 mt-6 pt-4 border-t border-n-weak"
        >
          <Button
            color="slate"
            size="sm"
            :disabled="pagination.currentPage === 1"
            @click="onPageChange(pagination.currentPage - 1)"
          >
            <span class="i-lucide-chevron-left size-4" />
            Anterior
          </Button>

          <div class="flex items-center gap-1">
            <template v-for="page in pagination.totalPages" :key="page">
              <button
                v-if="
                  page === 1 ||
                  page === pagination.totalPages ||
                  Math.abs(page - pagination.currentPage) <= 1
                "
                type="button"
                class="min-w-[32px] h-8 px-2 text-sm rounded-md transition-colors"
                :class="[
                  page === pagination.currentPage
                    ? 'bg-n-brand text-white font-medium'
                    : 'text-n-slate-11 hover:bg-n-alpha-2',
                ]"
                @click="onPageChange(page)"
              >
                {{ page }}
              </button>
              <span
                v-else-if="
                  (page === 2 && pagination.currentPage > 3) ||
                  (page === pagination.totalPages - 1 &&
                    pagination.currentPage < pagination.totalPages - 2)
                "
                class="text-n-slate-9 px-1"
              >
                ...
              </span>
            </template>
          </div>

          <Button
            color="slate"
            size="sm"
            :disabled="pagination.currentPage === pagination.totalPages"
            @click="onPageChange(pagination.currentPage + 1)"
          >
            Próxima
            <span class="i-lucide-chevron-right size-4" />
          </Button>
        </div>
      </div>
    </div>

    <!-- Painel de detalhes (sidebar direita) -->
    <TaskDetailPanel
      v-if="selectedTask"
      :task="selectedTask"
      @close="closeTaskDetails"
      @updated="onTaskUpdated"
      @deleted="onTaskDeleted"
    />
  </div>
</template>
