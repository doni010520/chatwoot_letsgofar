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

// Getters
const kanbanData = computed(() => store.getters['agentTasks/getKanbanData']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const filters = computed(() => store.getters['agentTasks/getFilters']);

// Task selecionada
const selectedTask = computed(() => store.getters['agentTasks/getCurrentTask']);

// Colunas do Kanban
const columns = computed(() => [
  {
    key: 'pending',
    title: t('TASKS.STATUS.PENDING'),
    icon: 'i-lucide-circle',
    color: 'text-n-slate-11',
    bgColor: 'bg-n-slate-3',
    tasks: kanbanData.value.pending || [],
  },
  {
    key: 'in_progress',
    title: t('TASKS.STATUS.IN_PROGRESS'),
    icon: 'i-lucide-loader',
    color: 'text-blue-11',
    bgColor: 'bg-blue-3',
    tasks: kanbanData.value.in_progress || [],
  },
  {
    key: 'completed',
    title: t('TASKS.STATUS.COMPLETED'),
    icon: 'i-lucide-check-circle',
    color: 'text-green-11',
    bgColor: 'bg-green-3',
    tasks: kanbanData.value.completed || [],
  },
  {
    key: 'cancelled',
    title: t('TASKS.STATUS.CANCELLED'),
    icon: 'i-lucide-x-circle',
    color: 'text-n-slate-9',
    bgColor: 'bg-n-slate-3',
    tasks: kanbanData.value.cancelled || [],
  },
]);

// Métodos
const loadKanban = () => {
  store.dispatch('agentTasks/fetchKanban');
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

const onDragEnd = () => {
  draggedTask.value = null;
  dragOverColumn.value = null;
};

// Lifecycle
onMounted(() => {
  loadKanban();
});

// Recarregar quando filtros mudarem
watch(
  filters,
  () => {
    loadKanban();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex h-full">
    <!-- Kanban Board -->
    <div class="flex-1 flex gap-4 p-4 overflow-x-auto">
      <!-- Loading -->
      <div v-if="uiFlags.isFetchingKanban" class="flex items-center justify-center w-full">
        <Spinner size="large" />
      </div>

      <!-- Colunas -->
      <template v-else>
        <div
          v-for="column in columns"
          :key="column.key"
          class="flex-shrink-0 w-80 flex flex-col rounded-xl bg-n-alpha-1"
          :class="{ 'ring-2 ring-n-brand ring-opacity-50': dragOverColumn === column.key }"
          @dragover="onDragOver($event, column.key)"
          @dragleave="onDragLeave"
          @drop="onDrop($event, column.key)"
        >
          <!-- Header da coluna -->
          <div class="flex items-center justify-between px-3 py-2 border-b border-n-weak">
            <div class="flex items-center gap-2">
