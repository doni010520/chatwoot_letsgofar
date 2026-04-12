<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import TaskDetailPanel from './TaskDetailPanel.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();

// Estado local
const currentDate = ref(new Date());
const selectedTaskId = ref(null);
const hoveredDay = ref(null);

// Getters
const calendarData = computed(() => store.getters['agentTasks/getCalendarData']);
const uiFlags = computed(() => store.getters['agentTasks/getUIFlags']);
const selectedTask = computed(() => store.getters['agentTasks/getCurrentTask']);

// Computed
const currentMonth = computed(() => currentDate.value.getMonth());
const currentYear = computed(() => currentDate.value.getFullYear());

const monthName = computed(() => {
  return currentDate.value.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
});

const weekDays = [
  { short: 'Dom', full: 'Domingo' },
  { short: 'Seg', full: 'Segunda' },
  { short: 'Ter', full: 'Terça' },
  { short: 'Qua', full: 'Quarta' },
  { short: 'Qui', full: 'Quinta' },
  { short: 'Sex', full: 'Sexta' },
  { short: 'Sáb', full: 'Sábado' },
];

// Gerar dias do calendário
const calendarDays = computed(() => {
  const year = currentYear.value;
  const month = currentMonth.value;

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const startPadding = firstDay.getDay();
  const totalDays = lastDay.getDate();

  const days = [];

  // Dias do mês anterior (padding)
  const prevMonth = new Date(year, month, 0);
  for (let i = startPadding - 1; i >= 0; i--) {
    const date = new Date(year, month - 1, prevMonth.getDate() - i);
    days.push({
      date,
      dateString: formatDateString(date),
      day: date.getDate(),
      isCurrentMonth: false,
      isToday: false,
      isWeekend: date.getDay() === 0 || date.getDay() === 6,
    });
  }

  // Dias do mês atual
  const today = new Date();
  for (let i = 1; i <= totalDays; i++) {
    const date = new Date(year, month, i);
    days.push({
      date,
      dateString: formatDateString(date),
      day: i,
      isCurrentMonth: true,
      isToday:
        date.getDate() === today.getDate() &&
        date.getMonth() === today.getMonth() &&
        date.getFullYear() === today.getFullYear(),
      isWeekend: date.getDay() === 0 || date.getDay() === 6,
    });
  }

  // Dias do próximo mês (padding para completar 6 semanas)
  const remaining = 42 - days.length;
  for (let i = 1; i <= remaining; i++) {
    const date = new Date(year, month + 1, i);
    days.push({
      date,
      dateString: formatDateString(date),
      day: i,
      isCurrentMonth: false,
      isToday: false,
      isWeekend: date.getDay() === 0 || date.getDay() === 6,
    });
  }

  return days;
});

// Helpers
const formatDateString = date => {
  return date.toISOString().split('T')[0];
};

const getTasksForDay = dateString => {
  return calendarData.value[dateString] || [];
};

// Cores por prioridade - usando sistema Radix UI do Chatwoot
const getPriorityStyle = (priority, status) => {
  // Se a tarefa estiver concluída, usar cor teal
  if (status === 'completed') {
    return 'bg-n-teal-9 text-white';
  }

  // Se cancelada, usar cor cinza
  if (status === 'cancelled') {
    return 'bg-n-slate-6 text-n-slate-11';
  }

  const styles = {
    urgent: 'bg-n-ruby-9 text-white',
    high: 'bg-n-amber-9 text-white',
    medium: 'bg-n-blue-9 text-white',
    low: 'bg-n-teal-9 text-white',
  };

  // Sempre retornar uma cor (default para azul se não tiver prioridade)
  return styles[priority] || 'bg-n-blue-9 text-white';
};

// Navegação
const goToPrevMonth = () => {
  currentDate.value = new Date(currentYear.value, currentMonth.value - 1, 1);
};

const goToNextMonth = () => {
  currentDate.value = new Date(currentYear.value, currentMonth.value + 1, 1);
};

const goToToday = () => {
  currentDate.value = new Date();
};

// Seleção de tarefa
const selectTask = async task => {
  selectedTaskId.value = task.id;
  await store.dispatch('agentTasks/fetchTask', task.id);
};

const closeDetailPanel = () => {
  selectedTaskId.value = null;
  store.dispatch('agentTasks/clearCurrentTask');
};

const onTaskUpdated = () => {
  loadCalendar();
};

const onTaskDeleted = () => {
  closeDetailPanel();
  loadCalendar();
};

// Carregar dados
const loadCalendar = () => {
  const startDate = new Date(currentYear.value, currentMonth.value, 1);
  const endDate = new Date(currentYear.value, currentMonth.value + 1, 0);

  store.dispatch('agentTasks/fetchCalendar', {
    startDate: formatDateString(startDate),
    endDate: formatDateString(endDate),
  });
};

// Lifecycle
onMounted(() => {
  loadCalendar();
});

// Recarregar quando mês mudar
watch([currentMonth, currentYear], () => {
  loadCalendar();
});
</script>

<template>
  <div class="flex h-full bg-n-alpha-1">
    <!-- Calendário -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header do Calendário - mais elegante -->
      <div class="flex items-center justify-between px-6 py-4 bg-n-background border-b border-n-weak">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1 bg-n-alpha-2 rounded-xl p-1">
            <button
              class="p-2 rounded-lg hover:bg-n-alpha-3 transition-colors"
              @click="goToPrevMonth"
            >
              <span class="i-lucide-chevron-left size-5 text-n-slate-11" />
            </button>
            <button
              class="p-2 rounded-lg hover:bg-n-alpha-3 transition-colors"
              @click="goToNextMonth"
            >
              <span class="i-lucide-chevron-right size-5 text-n-slate-11" />
            </button>
          </div>
          <h2 class="text-xl font-bold text-n-slate-12 capitalize">
            {{ monthName }}
          </h2>
        </div>

        <button 
          class="px-4 py-2 text-sm font-medium rounded-xl bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3 hover:text-n-slate-12 transition-colors"
          @click="goToToday"
        >
          Hoje
        </button>
      </div>

      <!-- Loading -->
      <div v-if="uiFlags.isFetchingCalendar" class="flex items-center justify-center flex-1">
        <Spinner size="large" />
      </div>

      <!-- Grid do Calendário -->
      <div v-else class="flex-1 overflow-auto p-4">
        <!-- Cabeçalho dos dias da semana -->
        <div class="grid grid-cols-7 gap-2 mb-3">
          <div
            v-for="(day, index) in weekDays"
            :key="day.short"
            class="text-center py-3 text-sm font-semibold rounded-xl"
            :class="[
              index === 0 || index === 6 
                ? 'text-n-slate-9 bg-n-alpha-1' 
                : 'text-n-slate-11 bg-n-alpha-2'
            ]"
          >
            {{ day.short }}
          </div>
        </div>

        <!-- Grid dos dias -->
        <div class="grid grid-cols-7 gap-2">
          <div
            v-for="day in calendarDays"
            :key="day.dateString"
            class="min-h-36 rounded-xl border transition-all duration-200"
            :class="[
              day.isCurrentMonth
                ? day.isWeekend 
                  ? 'bg-n-alpha-1 border-n-weak/50' 
                  : 'bg-n-background border-n-weak hover:border-n-slate-6 hover:shadow-sm'
                : 'bg-transparent border-transparent',
              day.isToday ? 'ring-2 ring-n-brand ring-offset-2 ring-offset-n-alpha-1' : '',
              hoveredDay === day.dateString && day.isCurrentMonth ? 'shadow-md' : '',
            ]"
            @mouseenter="hoveredDay = day.dateString"
            @mouseleave="hoveredDay = null"
          >
            <!-- Cabeçalho do dia -->
            <div class="flex items-center justify-between p-2 pb-1">
              <span
                class="text-sm font-bold w-8 h-8 flex items-center justify-center rounded-lg transition-colors"
                :class="[
                  day.isToday
                    ? 'bg-n-brand text-white'
                    : day.isCurrentMonth
                      ? 'text-n-slate-12'
                      : 'text-n-slate-6',
                ]"
              >
                {{ day.day }}
              </span>
              
              <!-- Badge de quantidade se tiver muitas tarefas -->
              <span 
                v-if="getTasksForDay(day.dateString).length > 3"
                class="text-xs font-medium px-2 py-0.5 rounded-full bg-n-alpha-3 text-n-slate-10"
              >
                {{ getTasksForDay(day.dateString).length }} tarefas
              </span>
            </div>

            <!-- Tarefas do dia -->
            <div 
              v-if="day.isCurrentMonth"
              class="px-2 pb-2 space-y-1.5 max-h-24 overflow-y-auto scrollbar-thin"
            >
              <button
                v-for="task in getTasksForDay(day.dateString).slice(0, 3)"
                :key="task.id"
                class="w-full text-left group"
                :title="`${task.due_time || ''} ${task.title}`"
                @click="selectTask(task)"
              >
                <div 
                  class="flex items-center gap-1.5 px-2 py-1.5 text-xs rounded-lg transition-all duration-150 group-hover:scale-[1.02] group-hover:shadow-sm"
                  :class="getPriorityStyle(task.priority, task.status)"
                >
                  <span v-if="task.due_time" class="font-bold flex-shrink-0 opacity-90">
                    {{ task.due_time }}
                  </span>
                  <span class="truncate font-medium">{{ task.title }}</span>
                </div>
              </button>

              <!-- Indicador de mais tarefas -->
              <button
                v-if="getTasksForDay(day.dateString).length > 3"
                class="w-full text-center text-xs text-n-slate-10 py-1 hover:text-n-slate-12 font-medium rounded-lg hover:bg-n-alpha-2 transition-colors"
              >
                +{{ getTasksForDay(day.dateString).length - 3 }} mais
              </button>
            </div>
          </div>
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

<style scoped>
.scrollbar-thin::-webkit-scrollbar {
  width: 4px;
}
.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-thin::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 2px;
}
.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.2);
}
</style>
