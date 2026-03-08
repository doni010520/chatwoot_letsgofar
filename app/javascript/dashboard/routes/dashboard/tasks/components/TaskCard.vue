<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click', 'complete']);

const { t } = useI18n();

// Cores por prioridade - mais sutis e elegantes
const priorityConfig = {
  urgent: { 
    label: 'Urgente',
    dot: 'bg-ruby-9',
    text: 'text-ruby-11',
  },
  high: { 
    label: 'Alta',
    dot: 'bg-orange-9',
    text: 'text-orange-11',
  },
  medium: { 
    label: 'Média',
    dot: 'bg-amber-9',
    text: 'text-amber-11',
  },
  low: { 
    label: 'Baixa',
    dot: 'bg-green-9',
    text: 'text-green-11',
  },
};

const priorityStyle = computed(() => priorityConfig[props.task.priority] || priorityConfig.medium);

// Formatar data de forma mais amigável
const formattedDueDate = computed(() => {
  if (!props.task.due_date) return null;

  // Parse manual para evitar problemas de timezone
  const [year, month, day] = props.task.due_date.split('-').map(Number);
  const dueDate = new Date(year, month - 1, day);
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const diffTime = dueDate.getTime() - today.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (dueDate.toDateString() === today.toDateString()) {
    return { text: 'Hoje', class: 'text-amber-11 bg-amber-3', isUrgent: true };
  }
  if (dueDate.toDateString() === tomorrow.toDateString()) {
    return { text: 'Amanhã', class: 'text-n-slate-11 bg-n-alpha-3', isUrgent: false };
  }
  if (diffDays < 0) {
    return { text: 'Atrasada', class: 'text-ruby-11 bg-ruby-3', isUrgent: true };
  }
  if (diffDays <= 7) {
    const weekday = dueDate.toLocaleDateString('pt-BR', { weekday: 'short' });
    const dayNum = dueDate.getDate();
    return {
      text: `${weekday}, ${dayNum}`,
      class: 'text-n-slate-11 bg-n-alpha-3',
      isUrgent: false,
    };
  }

  return {
    text: dueDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }),
    class: 'text-n-slate-10 bg-n-alpha-2',
    isUrgent: false,
  };
});

// Checklist progress
const checklistProgress = computed(() => {
  if (!props.task.items_count || props.task.items_count === 0) return null;
  return {
    completed: props.task.items_completed_count || 0,
    total: props.task.items_count,
    percentage: Math.round(((props.task.items_completed_count || 0) / props.task.items_count) * 100),
  };
});

const isCompleted = computed(() => props.task.status === 'completed');

// Handlers
const handleClick = () => {
  emit('click', props.task);
};

const handleComplete = e => {
  e.stopPropagation();
  if (!isCompleted.value) {
    emit('complete', props.task);
  }
};
</script>

<template>
  <div
    class="group relative rounded-xl border transition-all duration-200 cursor-pointer"
    :class="[
      isSelected
        ? 'border-n-brand bg-n-brand/5 shadow-sm'
        : 'border-n-weak bg-n-background hover:border-n-slate-6 hover:shadow-sm',
      isCompleted ? 'opacity-50' : '',
    ]"
    @click="handleClick"
  >
    <!-- Barra de prioridade no topo -->
    <div 
      class="absolute top-0 left-4 right-4 h-0.5 rounded-full opacity-60"
      :class="priorityStyle.dot"
    />

    <div class="p-4 pt-3">
      <div class="flex items-start gap-3">
        <!-- Checkbox elegante -->
        <button
          class="flex-shrink-0 mt-0.5 size-5 rounded-md border-2 flex items-center justify-center transition-all duration-200"
          :class="[
            isCompleted
              ? 'border-green-9 bg-green-9 text-white'
              : 'border-n-slate-6 hover:border-n-brand hover:bg-n-brand/10',
          ]"
          @click="handleComplete"
        >
          <span v-if="isCompleted" class="i-lucide-check size-3" />
        </button>

        <!-- Conteúdo principal -->
        <div class="flex-1 min-w-0">
          <!-- Título -->
          <h3
            class="text-sm font-medium leading-tight mb-2"
            :class="isCompleted ? 'line-through text-n-slate-9' : 'text-n-slate-12'"
          >
            {{ task.title }}
          </h3>

          <!-- Meta informações em linha -->
          <div class="flex items-center gap-3 flex-wrap">
            <!-- Prioridade - apenas bolinha colorida com texto -->
            <span class="inline-flex items-center gap-1.5 text-xs" :class="priorityStyle.text">
              <span class="size-2 rounded-full" :class="priorityStyle.dot" />
              {{ priorityStyle.label }}
            </span>

            <!-- Data de vencimento -->
            <span
              v-if="formattedDueDate"
              class="inline-flex items-center gap-1.5 text-xs px-2 py-0.5 rounded-md"
              :class="formattedDueDate.class"
            >
              <span class="i-lucide-calendar size-3" />
              {{ formattedDueDate.text }}
              <span v-if="task.due_time" class="opacity-70">
                {{ task.due_time }}
              </span>
            </span>

            <!-- Progress de checklist -->
            <span
              v-if="checklistProgress"
              class="inline-flex items-center gap-1.5 text-xs text-n-slate-10"
            >
              <span class="i-lucide-list-checks size-3" />
              {{ checklistProgress.completed }}/{{ checklistProgress.total }}
            </span>

            <!-- Comentários -->
            <span
              v-if="task.comments_count > 0"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              <span class="i-lucide-message-circle size-3" />
              {{ task.comments_count }}
            </span>

            <!-- Anexos -->
            <span
              v-if="task.files_count > 0"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              <span class="i-lucide-paperclip size-3" />
              {{ task.files_count }}
            </span>
          </div>

          <!-- Labels (se houver) -->
          <div v-if="task.labels && task.labels.length > 0" class="flex items-center gap-1.5 mt-2">
            <span
              v-for="label in task.labels.slice(0, 2)"
              :key="label.id"
              class="px-2 py-0.5 text-xs rounded-full font-medium"
              :style="{ 
                backgroundColor: label.color + '20', 
                color: label.color,
                border: `1px solid ${label.color}30`
              }"
            >
              {{ label.title }}
            </span>
            <span
              v-if="task.labels.length > 2"
              class="text-xs text-n-slate-9"
            >
              +{{ task.labels.length - 2 }}
            </span>
          </div>

          <!-- Contato vinculado (se houver) -->
          <div
            v-if="task.contact"
            class="flex items-center gap-1.5 mt-2 text-xs text-n-slate-10"
          >
            <span class="i-lucide-user size-3" />
            <span>{{ task.contact.name }}</span>
          </div>
        </div>

        <!-- Avatar do responsável -->
        <div class="flex-shrink-0">
          <Avatar
            v-if="task.assigned_to"
            :name="task.assigned_to.name"
            :src="task.assigned_to.avatar_url"
            size="28px"
            :title="task.assigned_to.name"
            class="ring-2 ring-n-background"
          />
          <div
            v-else
            class="size-7 rounded-full bg-n-alpha-2 border border-dashed border-n-slate-6 flex items-center justify-center"
            :title="t('TASKS.UNASSIGNED')"
          >
            <span class="i-lucide-user-plus size-3.5 text-n-slate-8" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
