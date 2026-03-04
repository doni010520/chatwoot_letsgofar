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

// Cores por prioridade
const priorityConfig = {
  urgent: { color: 'text-ruby-11', bg: 'bg-ruby-3', icon: 'i-lucide-alert-circle' },
  high: { color: 'text-orange-11', bg: 'bg-orange-3', icon: 'i-lucide-arrow-up' },
  medium: { color: 'text-amber-11', bg: 'bg-amber-3', icon: 'i-lucide-minus' },
  low: { color: 'text-green-11', bg: 'bg-green-3', icon: 'i-lucide-arrow-down' },
};

const priorityStyle = computed(() => priorityConfig[props.task.priority] || priorityConfig.medium);

// Formatar data
const formattedDueDate = computed(() => {
  if (!props.task.due_date) return null;

  const dueDate = new Date(props.task.due_date);
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const diffDays = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

  if (dueDate.toDateString() === today.toDateString()) {
    return { text: t('TASKS.DUE_DATE.TODAY'), class: 'text-amber-11' };
  }
  if (dueDate.toDateString() === tomorrow.toDateString()) {
    return { text: t('TASKS.DUE_DATE.TOMORROW'), class: 'text-n-slate-11' };
  }
  if (diffDays < 0) {
    return { text: t('TASKS.DUE_DATE.OVERDUE'), class: 'text-ruby-11 font-medium' };
  }
  if (diffDays <= 7) {
    return {
      text: dueDate.toLocaleDateString('pt-BR', { weekday: 'short', day: 'numeric' }),
      class: 'text-n-slate-11',
    };
  }

  return {
    text: dueDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }),
    class: 'text-n-slate-10',
  };
});

// Checklist progress
const checklistProgress = computed(() => {
  if (!props.task.items_count || props.task.items_count === 0) return null;
  return `${props.task.items_completed_count || 0}/${props.task.items_count}`;
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
    class="group flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-all"
    :class="[
      isSelected
        ? 'border-n-brand bg-n-brand/5'
        : 'border-n-weak hover:border-n-slate-7 hover:bg-n-alpha-1',
      isCompleted ? 'opacity-60' : '',
    ]"
    @click="handleClick"
  >
    <!-- Checkbox -->
    <button
      class="flex-shrink-0 mt-0.5 size-5 rounded-full border-2 flex items-center justify-center transition-colors"
      :class="[
        isCompleted
          ? 'border-green-9 bg-green-9 text-white'
          : 'border-n-slate-7 hover:border-n-brand group-hover:border-n-slate-8',
      ]"
      @click="handleComplete"
    >
      <span v-if="isCompleted" class="i-lucide-check size-3" />
    </button>

    <!-- Conteúdo -->
    <div class="flex-1 min-w-0">
      <div class="flex items-start justify-between gap-2">
        <div class="flex-1 min-w-0">
          <!-- Título -->
          <h3
            class="text-sm font-medium truncate"
            :class="isCompleted ? 'line-through text-n-slate-10' : 'text-n-slate-12'"
          >
            {{ task.title }}
          </h3>

          <!-- Meta info -->
          <div class="flex items-center gap-2 mt-1 flex-wrap">
            <!-- Prioridade -->
            <span
              class="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs rounded"
              :class="[priorityStyle.bg, priorityStyle.color]"
            >
              <span :class="priorityStyle.icon" class="size-3" />
              {{ t(`TASKS.PRIORITY.${task.priority.toUpperCase()}`) }}
            </span>

            <!-- Data de vencimento -->
            <span
              v-if="formattedDueDate"
              class="inline-flex items-center gap-1 text-xs"
              :class="formattedDueDate.class"
            >
              <span class="i-lucide-calendar size-3" />
              {{ formattedDueDate.text }}
              <span v-if="task.due_time" class="text-n-slate-10">
                {{ task.due_time }}
              </span>
            </span>

            <!-- Checklist -->
            <span
              v-if="checklistProgress"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              <span class="i-lucide-check-square size-3" />
              {{ checklistProgress }}
            </span>

            <!-- Comentários -->
            <span
              v-if="task.comments_count > 0"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              <span class="i-lucide-message-square size-3" />
              {{ task.comments_count }}
            </span>

            <!-- Vínculo com contato -->
            <span
              v-if="task.contact"
              class="inline-flex items-center gap-1 text-xs text-n-slate-10"
            >
              <span class="i-lucide-user size-3" />
              {{ task.contact.name }}
            </span>
          </div>

          <!-- Labels -->
          <div v-if="task.labels && task.labels.length > 0" class="flex items-center gap-1 mt-2">
            <span
              v-for="label in task.labels.slice(0, 3)"
              :key="label.id"
              class="px-1.5 py-0.5 text-xs rounded"
              :style="{ backgroundColor: label.color + '20', color: label.color }"
            >
              {{ label.title }}
            </span>
            <span
              v-if="task.labels.length > 3"
              class="text-xs text-n-slate-10"
            >
              +{{ task.labels.length - 3 }}
            </span>
          </div>
        </div>

        <!-- Avatar do responsável -->
        <div v-if="task.assigned_to" class="flex-shrink-0">
          <Avatar
            :name="task.assigned_to.name"
            :src="task.assigned_to.avatar_url"
            size="24px"
            :title="task.assigned_to.name"
          />
        </div>
        <div
          v-else
          class="flex-shrink-0 size-6 rounded-full border-2 border-dashed border-n-slate-6 flex items-center justify-center"
          :title="t('TASKS.UNASSIGNED')"
        >
          <span class="i-lucide-user size-3 text-n-slate-8" />
        </div>
      </div>
    </div>
  </div>
</template>
