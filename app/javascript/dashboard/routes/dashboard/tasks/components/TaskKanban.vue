<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const isInitialized = ref(false);

// Debounce timer
let debounceTimer = null;

// Colunas do Kanban
const columns = [
  { key: 'pending', label: 'Pendente', icon: 'i-lucide-circle-dashed', color: 'slate' },
  { key: 'in_progress', label: 'Em Andamento', icon: 'i-lucide-play-circle', color: 'blue' },
  { key: 'completed', label: 'Concluída', icon: 'i-lucide-check-circle', color: 'green' },
  { key: 'cancelled', label: 'Cancelada', icon: 'i-lucide-x-circle', color: 'gray' },
];

// Getters
const kanbanData = computed(() => store.getters['agentTasks/getKanban'] || {});
const filters = computed(() => store.getters['agentTasks/getFilters']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);

// Obter tarefas por coluna
const getColumnTasks = status => {
  const data = kanbanData.value;
  if (!data || !data.data) return [];
  return data.data[status] || [];
};

const getColumnCount = status => {
  return getColumnTasks(status).length;
};

// Fetch com debounce
const fetchKanban = () => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
  debounceTimer = setTimeout(() => {
    store.dispatch('agentTasks/fetchKanban');
  }, 150);
};

// Formatação
const formatDueDate = task => {
  if (!task.due_date) return null;
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const [year, month, day] = task.due_date.split('-').map(Number);
  const dueDate = new Date(year, month - 1, day);
  dueDate.setHours(0, 0, 0, 0);
  
  const diffDays = Math.floor((dueDate - today) / (1000 * 60 * 60 * 24));
  
  if (diffDays < 0) {
    return { text: 'Atrasada', class: 'text-ruby-11', isOverdue: true };
  } else if (diffDays === 0) {
    return { text: 'Hoje', class: 'text-amber-11', isOverdue: false };
  } else if (diffDays === 1) {
    return { text: 'Amanhã', class: 'text-blue-11', isOverdue: false };
  } else {
    const formatted = dueDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
    return { text: formatted, class: 'text-n-slate-11', isOverdue: false };
  }
};

const getPriorityConfig = priority => {
  const configs = {
    urgent: { label: 'Urgente', bg: 'bg-ruby-3', text: 'text-ruby-11', border: 'border-ruby-6' },
    high: { label: 'Alta', bg: 'bg-orange-3', text: 'text-orange-11', border: 'border-orange-6' },
    medium: { label: 'Média', bg: 'bg-amber-3', text: 'text-amber-11', border: 'border-amber-6' },
    low: { label: 'Baixa', bg: 'bg-green-3', text: 'text-green-11', border: 'border-green-6' },
  };
  return configs[priority] || configs.medium;
};

const getColumnHeaderColor = color => {
  const colors = {
    slate: 'border-slate-500',
    blue: 'border-blue-500',
    green: 'border-green-500',
    gray: 'border-gray-500',
  };
  return colors[color] || colors.slate;
};

const getColumnCountBg = color => {
  const colors = {
    slate: 'bg-slate-500/20 text-slate-300',
    blue: 'bg-blue-500/20 text-blue-300',
    green: 'bg-green-500/20 text-green-300',
    gray: 'bg-gray-500/20 text-gray-300',
  };
  return colors[color] || colors.slate;
};

// Watch filters
watch(
  () => filters.value,
  () => {
    if (isInitialized.value) {
      fetchKanban();
    }
  },
  { deep: true }
);

// Carregar dados iniciais
onMounted(() => {
  setTimeout(() => {
    isInitialized.value = true;
    fetchKanban();
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
  <div class="h-full overflow-x-auto p-4 bg-n-background">
    <!-- Loading -->
    <div v-if="uiFlags.isLoading && !kanbanData.data" class="flex items-center justify-center h-full">
      <div class="flex flex-col items-center gap-3">
        <span class="i-lucide-loader-2 size-8 text-n-brand animate-spin" />
        <span class="text-sm text-n-slate-11">Carregando...</span>
      </div>
    </div>

    <!-- Kanban Board -->
    <div v-else class="flex gap-4 h-full min-w-max">
      <div
        v-for="column in columns"
        :key="column.key"
        class="w-80 min-w-[320px] flex flex-col rounded-xl border border-n-weak bg-n-alpha-1 overflow-hidden"
      >
        <!-- Header da Coluna -->
        <div 
          class="flex items-center justify-between px-4 py-3 border-b-2 bg-n-surface-2"
          :class="getColumnHeaderColor(column.color)"
        >
          <div class="flex items-center gap-2">
            <span :class="column.icon" class="size-5" />
            <span class="font-semibold text-n-slate-12">{{ column.label }}</span>
          </div>
          <span 
            class="px-2 py-0.5 text-sm font-medium rounded-full"
            :class="getColumnCountBg(column.color)"
          >
            {{ getColumnCount(column.key) }}
          </span>
        </div>

        <!-- Lista de Cards -->
        <div class="flex-1 overflow-y-auto p-3 space-y-3">
          <div
            v-for="task in getColumnTasks(column.key)"
            :key="task.id"
            class="p-4 rounded-lg border border-n-weak bg-n-surface-3 hover:border-n-slate-8 cursor-pointer transition-all hover:shadow-lg"
          >
            <!-- Header do Card: Título + Avatar -->
            <div class="flex items-start justify-between gap-2 mb-2">
              <h4 class="font-medium text-n-slate-12 leading-tight">
                {{ task.title }}
              </h4>
              <Avatar
                v-if="task.assigned_to"
                :name="task.assigned_to.name"
                :src="task.assigned_to.avatar_url"
                size="24px"
                class="flex-shrink-0"
              />
            </div>

            <!-- Badges: Prioridade + Data -->
            <div class="flex items-center flex-wrap gap-2 mt-3">
              <span 
                class="px-2 py-0.5 text-xs font-medium rounded border"
                :class="[getPriorityConfig(task.priority).bg, getPriorityConfig(task.priority).text, getPriorityConfig(task.priority).border]"
              >
                {{ getPriorityConfig(task.priority).label }}
              </span>

              <span 
                v-if="formatDueDate(task)"
                class="flex items-center gap-1 text-xs"
                :class="formatDueDate(task).class"
              >
                <span class="i-lucide-calendar size-3" />
                {{ formatDueDate(task).text }}
                <span v-if="task.due_time" class="opacity-75">{{ task.due_time }}</span>
              </span>
            </div>

            <!-- Subtarefas -->
            <div 
              v-if="task.items_count > 0" 
              class="flex items-center gap-1 mt-2 text-xs text-n-slate-10"
            >
              <span class="i-lucide-list-checks size-3" />
              {{ task.items_completed_count || 0 }}/{{ task.items_count }}
            </div>
          </div>

          <!-- Empty State -->
          <div
            v-if="getColumnTasks(column.key).length === 0"
            class="flex flex-col items-center justify-center py-8 text-center"
          >
            <span class="i-lucide-inbox size-8 text-n-slate-8 mb-2" />
            <span class="text-sm text-n-slate-10">Nenhuma tarefa</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
