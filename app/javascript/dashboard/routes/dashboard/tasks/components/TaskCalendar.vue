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

const weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

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

// Cores por prioridade
const priorityColors = {
  urgent: 'bg-ruby-9 text-white',
  high: 'bg-orange-9 text-white',
  medium: 'bg-amber-9 text-white',
  low: 'bg-green-9 text-white',
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
  <div class="flex h-full">
    <!-- Calendário -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header do Calendário -->
      <div class="flex items-center justify-between px-4 py-3 border-b border-n-weak">
        <div class="flex items-center gap-2">
          <Button
            icon="i-lucide-chevron-left"
            color="slate"
            size="sm"
            @click="goToPrevMonth"
          />
          <Button
            icon="i-lucide-chevron-right"
            color="slate"
            size="sm"
            @click="goToNextMonth"
          />
          <h2 class="text-lg font-semibold text-n-slate-12 capitalize ml-2">
            {{ monthName }}
          </h2>
        </div>

        <div class="flex items-center gap-2">
          <Button color="slate" size="sm" @click="goToToday">
            {{ t('TASKS.CALENDAR.TODAY') }}
          </Button>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="uiFlags.isFetchingCalendar" class="flex items-center justify-center flex-1">
        <Spinner size="large" />
      </div>

      <!-- Grid do Calendário -->
      <div v-else class="flex-1 overflow-auto p-4">
        <!-- Cabeçalho dos dias da semana -->
        <div class="grid grid-cols-7 gap-1 mb-2">
          <div
            v-for="day in weekDays"
            :key="day"
            class="text-center text-sm font-medium text-n-slate-10 py-2"
          >
            {{ day }}
          </div>
        </div>

        <!-- Grid dos dias -->
        <div class="grid grid-cols-7 gap-1">
          <div
            v-for="day in calendarDays"
            :key="day.dateString"
            class="min-h-28 p-1 rounded-lg border transition-colors"
            :class="[
              day.isCurrentMonth
                ? 'border-n-weak bg-n-background'
                : 'border-transparent bg-n-alpha-1',
              day.isToday ? 'ring-2 ring-n-brand' : '',
            ]"
          >
            <!-- Número do dia -->
            <div
              class="text-sm font-medium mb-1 px-1"
              :class="[
                day.isToday
                  ? 'text-n-brand'
                  : day.isCurrentMonth
                    ? 'text-n-slate-12'
                    : 'text-n-slate-8',
              ]"
            >
              {{ day.day }}
            </div>

            <!-- Tarefas do dia -->
            <div class="space-y-0.5 max-h-20 overflow-y-auto">
              <button
                v-for="task in getTasksForDay(day.dateString).slice(0, 3)"
                :key="task.id"
                class="w-full text-left px-1.5 py-0.5 text-xs rounded truncate"
                :class="priorityColors[task.priority]"
                :title="task.title"
                @click="selectTask(task)"
              >
                <span v-if="task.due_time" class="opacity-75 mr-1">
                  {{ task.due_time }}
                </span>
                {{ task.title }}
              </button>

              <!-- Indicador de mais tarefas -->
              <div
                v-if="getTasksForDay(day.dateString).length > 3"
                class="text-xs text-n-slate-10 px-1"
              >
                +{{ getTasksForDay(day.dateString).length - 3 }} mais
              </div>
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
