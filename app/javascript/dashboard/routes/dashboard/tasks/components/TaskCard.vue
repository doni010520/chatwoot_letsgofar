<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['click', 'updated']);

const { t } = useI18n();

// Configuração de prioridade
const priorityConfig = computed(() => {
  const configs = {
    urgent: { 
      label: 'Urgente', 
      bg: 'bg-ruby-500/20', 
      text: 'text-ruby-400',
      border: 'border-ruby-500/40',
      bar: 'bg-ruby-500'
    },
    high: { 
      label: 'Alta', 
      bg: 'bg-orange-500/20', 
      text: 'text-orange-400',
      border: 'border-orange-500/40',
      bar: 'bg-orange-500'
    },
    medium: { 
      label: 'Média', 
      bg: 'bg-amber-500/20', 
      text: 'text-amber-400',
      border: 'border-amber-500/40',
      bar: 'bg-amber-500'
    },
    low: { 
      label: 'Baixa', 
      bg: 'bg-green-500/20', 
      text: 'text-green-400',
      border: 'border-green-500/40',
      bar: 'bg-green-500'
    },
  };
  return configs[props.task.priority] || configs.medium;
});

// Data de vencimento
const dueInfo = computed(() => {
  if (!props.task.due_date) return null;
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const [year, month, day] = props.task.due_date.split('-').map(Number);
  const dueDate = new Date(year, month - 1, day);
  dueDate.setHours(0, 0, 0, 0);
  
  const diffDays = Math.floor((dueDate - today) / (1000 * 60 * 60 * 24));
  
  if (diffDays < 0) {
    return { text: 'Atrasada', class: 'text-ruby-400 bg-ruby-500/10', isOverdue: true };
  } else if (diffDays === 0) {
    return { text: 'Hoje', class: 'text-amber-400 bg-amber-500/10', isOverdue: false };
  } else if (diffDays === 1) {
    return { text: 'Amanhã', class: 'text-blue-400 bg-blue-500/10', isOverdue: false };
  } else {
    const formatted = dueDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
    return { text: formatted, class: 'text-n-slate-11 bg-n-alpha-2', isOverdue: false };
  }
});

// Status
const statusConfig = computed(() => {
  const configs = {
    pending: { label: 'Pendente', icon: 'i-lucide-circle-dashed', color: 'text-slate-400' },
    in_progress: { label: 'Em Andamento', icon: 'i-lucide-play-circle', color: 'text-blue-400' },
    completed: { label: 'Concluída', icon: 'i-lucide-check-circle', color: 'text-green-400' },
    cancelled: { label: 'Cancelada', icon: 'i-lucide-x-circle', color: 'text-gray-400' },
  };
  return configs[props.task.status] || configs.pending;
});

const handleClick = () => {
  emit('click', props.task);
};
</script>

<template>
  <div
    class="task-card"
    @click="handleClick"
  >
    <!-- Barra de prioridade no topo -->
    <div class="task-card-bar" :class="priorityConfig.bar" />
    
    <div class="task-card-content">
      <!-- Header: Título + Avatar -->
      <div class="flex items-start justify-between gap-3 mb-3">
        <h3 class="font-semibold text-n-slate-12 leading-tight flex-1">
          {{ task.title }}
        </h3>
        <Avatar
          v-if="task.assigned_to"
          :name="task.assigned_to.name"
          :src="task.assigned_to.avatar_url"
          size="28px"
          class="flex-shrink-0"
        />
      </div>

      <!-- Descrição (se houver) -->
      <p 
        v-if="task.description" 
        class="text-sm text-n-slate-11 mb-3 line-clamp-2"
      >
        {{ task.description }}
      </p>

      <!-- Footer: Badges -->
      <div class="flex items-center flex-wrap gap-2">
        <!-- Prioridade -->
        <span 
          class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md border"
          :class="[priorityConfig.bg, priorityConfig.text, priorityConfig.border]"
        >
          {{ priorityConfig.label }}
        </span>

        <!-- Data de vencimento -->
        <span 
          v-if="dueInfo"
          class="inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-md"
          :class="dueInfo.class"
        >
          <span class="i-lucide-calendar size-3" />
          {{ dueInfo.text }}
          <span v-if="task.due_time" class="opacity-80">{{ task.due_time }}</span>
        </span>

        <!-- Subtarefas -->
        <span 
          v-if="task.items_count > 0"
          class="inline-flex items-center gap-1 px-2 py-0.5 text-xs text-n-slate-11 bg-n-alpha-2 rounded-md"
        >
          <span class="i-lucide-list-checks size-3" />
          {{ task.items_completed_count || 0 }}/{{ task.items_count }}
        </span>

        <!-- Comentários -->
        <span 
          v-if="task.comments_count > 0"
          class="inline-flex items-center gap-1 px-2 py-0.5 text-xs text-n-slate-11 bg-n-alpha-2 rounded-md"
        >
          <span class="i-lucide-message-circle size-3" />
          {{ task.comments_count }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.task-card {
  position: relative;
  background: linear-gradient(135deg, rgba(51, 65, 85, 0.8) 0%, rgba(30, 41, 59, 0.9) 100%);
  border: 1px solid rgba(100, 116, 139, 0.4);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.task-card:hover {
  border-color: rgba(100, 116, 139, 0.6);
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
}

.task-card-bar {
  height: 3px;
  width: 100%;
}

.task-card-content {
  padding: 14px 16px;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
