<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import TaskCard from './TaskCard.vue';
import TaskDetailPanel from './TaskDetailPanel.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const selectedTaskId = ref(null);
const draggedTask = ref(null);
const dragOverColumn = ref(null);
let debounceTimer = null;
const isInitialized = ref(false);

// Getters
const kanbanData = computed(() => store.getters['agentTasks/getKanbanData']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const filters = computed(() => store.getters['agentTasks/getFilters']);

// Task selecionada
const selectedTask = computed(() => store.getters['agentTasks/getCurrentTask']);

// Colunas do Kanban - visual mais distinto
const columns = computed(() => [
  {
    key: 'pending',
    title: 'Pendente',
    icon: 'i-lucide-circle-dashed',
    headerBg: 'bg-slate-500/10',
    headerBorder: 'border-slate-400/30',
    iconColor: 'text-slate-500',
    countBg: 'bg-slate-500/20',
    countText: 'text-slate-600',
    dropZone: 'border-slate-400',
    tasks: kanbanData.value.pending || [],
  },
  {
    key: 'in_progress',
    title: 'Em Andamento',
    icon: 'i-lucide-play-circle',
    headerBg: 'bg-blue-500/10',
    headerBorder: 'border-blue-400/30',
    iconColor: 'text-blue-500',
    countBg: 'bg-blue-500/20',
    countText: 'text-blue-600',
    dropZone: 'border-blue-400',
    tasks: kanbanData.value.in_progress || [],
  },
  {
    key: 'completed',
    title: 'Concluída',
    icon: 'i-lucide-check-circle-2',
    headerBg: 'bg-green-500/10',
    headerBorder: 'border-green-400/30',
    iconColor: 'text-green-500',
    countBg: 'bg-green-500/20',
    countText: 'text-green-600',
    dropZone: 'border-green-400',
    tasks: kanbanData.value.completed || [],
  },
  {
    key: 'cancelled',
    title: 'Cancelada',
    icon: 'i-lucide-x-circle',
    headerBg: 'bg-n-slate-500/10',
    headerBorder: 'border-n-slate-400/30',
    iconColor: 'text-n-slate-400',
    countBg: 'bg-n-slate-500/20',
    countText: 'text-n-slate-500',
    dropZone: 'border-n-slate-400',
    tasks: kanbanData.value.cancelled || [],
  },
]);

// Métodos
const loadKanban = () => {
  store.dispatch('agentTasks/fetchKanban');
};

const debouncedLoadKanban = () => {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    loadKanban();
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
  loadKanban();
};

const onTaskDeleted = () => {
  closeDetailPanel();
  loadKanban();
};

// Drag & Drop handlers
const onDragStart = (event, task, fromColumn) => {
  draggedTask.value = { task, fromColumn };
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', task.id);
  // Adiciona classe ao elemento sendo arrastado
  event.target.classList.add('opacity-50', 'scale-95');
};

const onDragOver = (event, columnKey) => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
  dragOverColumn.value = columnKey;
};

const onDragLeave = () => {
  dragOverColumn.value = null;
};

const onDrop = async (event, toColumn) => {
  event.preventDefault();
  dragOverColumn.value = null;

  if (!draggedTask.value) return;

  const { task, fromColumn } = draggedTask.value;

  if (fromColumn === toColumn) {
    draggedTask.value = null;
    return;
  }

  // Atualização otimista
  store.commit('agentTasks/MOVE_TASK_KANBAN', {
    taskId: task.id,
    fromStatus: fromColumn,
    toStatus: toColumn,
  });

  try {
    await store.dispatch('agentTasks/updateTask', {
      taskId: task.id,
      taskData: { status: toColumn },
    });
    store.dispatch('agentTasks/fetchStats');
  } catch (error) {
    // Reverter em caso de erro
    store.commit('agentTasks/MOVE_TASK_KANBAN', {
      taskId: task.id,
      fromStatus: toColumn,
      toStatus: fromColumn,
    });
  }

  draggedTask.value = null;
};

const onDragEnd = event => {
  draggedTask.value = null;
  dragOverColumn.value = null;
  // Remove classe do elemento
  event.target.classList.remove('opacity-50', 'scale-95');
};

// Lifecycle
onMounted(async () => {
  await loadKanban();
  setTimeout(() => {
    isInitialized.value = true;
  }, 200);
});

// Recarregar quando filtros mudarem
watch(
  filters,
  () => {
    if (isInitialized.value) {
      debouncedLoadKanban();
    }
  },
  { deep: true }
);
</script>

<template>
  <div class="flex h-full bg-n-alpha-1">
    <!-- Kanban Board -->
    <div class="flex-1 flex gap-5 p-5 overflow-x-auto">
      <!-- Loading -->
      <div v-if="uiFlags.isFetchingKanban && !isInitialized" class="flex items-center justify-center w-full">
        <Spinner size="large" />
      </div>

      <!-- Colunas -->
      <template v-else>
        <div
          v-for="column in columns"
          :key="column.key"
          class="flex-shrink-0 w-80 flex flex-col rounded-2xl bg-n-background border border-n-weak transition-all duration-200"
          :class="{ 
            'ring-2 ring-offset-2 ring-offset-n-alpha-1': dragOverColumn === column.key,
            [column.dropZone]: dragOverColumn === column.key 
          }"
          @dragover="onDragOver($event, column.key)"
          @dragleave="onDragLeave"
          @drop="onDrop($event, column.key)"
        >
          <!-- Header da coluna - mais visual -->
          <div 
            class="flex items-center justify-between px-4 py-3 rounded-t-2xl border-b"
            :class="[column.headerBg, column.headerBorder]"
          >
            <div class="flex items-center gap-2.5">
              <span :class="[column.icon, column.iconColor]" class="size-5" />
              <span class="font-semibold text-sm text-n-slate-12">
                {{ column.title }}
              </span>
            </div>
            <span
              class="px-2.5 py-1 text-xs font-bold rounded-full"
              :class="[column.countBg, column.countText]"
            >
              {{ column.tasks.length }}
            </span>
          </div>

          <!-- Cards da coluna -->
          <div class="flex-1 overflow-y-auto p-3 space-y-3">
            <div
              v-for="task in column.tasks"
              :key="task.id"
              draggable="true"
              class="cursor-grab active:cursor-grabbing transition-transform duration-200"
              @dragstart="onDragStart($event, task, column.key)"
              @dragend="onDragEnd"
            >
              <TaskCard
                :task="task"
                :is-selected="selectedTaskId === task.id"
                compact
                @click="selectTask(task)"
              />
            </div>

            <!-- Empty state mais visual -->
            <div
              v-if="column.tasks.length === 0"
              class="flex flex-col items-center justify-center py-12 px-4"
            >
              <div 
                class="size-16 rounded-2xl flex items-center justify-center mb-3"
                :class="column.headerBg"
              >
                <span :class="[column.icon, column.iconColor]" class="size-8 opacity-50" />
              </div>
              <span class="text-sm text-n-slate-9 text-center">
                Nenhuma tarefa
              </span>
            </div>
          </div>
        </div>
      </template>
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
