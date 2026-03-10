<script setup>
import { computed } from 'vue';

const props = defineProps({
  activities: {
    type: Array,
    default: () => [],
  },
});

// Configuração de ícones e cores por tipo
const getActivityConfig = (type) => {
  const configs = {
    created: {
      icon: 'i-lucide-file-plus',
      bgColor: 'bg-blue-100 dark:bg-blue-900/30',
      iconColor: 'text-blue-600 dark:text-blue-400',
      lineColor: 'bg-blue-200 dark:bg-blue-800',
    },
    edited: {
      icon: 'i-lucide-edit',
      bgColor: 'bg-amber-100 dark:bg-amber-900/30',
      iconColor: 'text-amber-600 dark:text-amber-400',
      lineColor: 'bg-amber-200 dark:bg-amber-800',
    },
    sent: {
      icon: 'i-lucide-send',
      bgColor: 'bg-indigo-100 dark:bg-indigo-900/30',
      iconColor: 'text-indigo-600 dark:text-indigo-400',
      lineColor: 'bg-indigo-200 dark:bg-indigo-800',
    },
    viewed: {
      icon: 'i-lucide-eye',
      bgColor: 'bg-slate-100 dark:bg-slate-800',
      iconColor: 'text-slate-500 dark:text-slate-400',
      lineColor: 'bg-slate-200 dark:bg-slate-700',
    },
    signed: {
      icon: 'i-lucide-check-circle',
      bgColor: 'bg-green-100 dark:bg-green-900/30',
      iconColor: 'text-green-600 dark:text-green-400',
      lineColor: 'bg-green-200 dark:bg-green-800',
    },
    refused: {
      icon: 'i-lucide-x-circle',
      bgColor: 'bg-red-100 dark:bg-red-900/30',
      iconColor: 'text-red-600 dark:text-red-400',
      lineColor: 'bg-red-200 dark:bg-red-800',
    },
    expired: {
      icon: 'i-lucide-clock',
      bgColor: 'bg-orange-100 dark:bg-orange-900/30',
      iconColor: 'text-orange-600 dark:text-orange-400',
      lineColor: 'bg-orange-200 dark:bg-orange-800',
    },
    cancelled: {
      icon: 'i-lucide-ban',
      bgColor: 'bg-slate-100 dark:bg-slate-800',
      iconColor: 'text-slate-500 dark:text-slate-400',
      lineColor: 'bg-slate-200 dark:bg-slate-700',
    },
    reminder_sent: {
      icon: 'i-lucide-bell',
      bgColor: 'bg-purple-100 dark:bg-purple-900/30',
      iconColor: 'text-purple-600 dark:text-purple-400',
      lineColor: 'bg-purple-200 dark:bg-purple-800',
    },
  };

  return configs[type] || configs.created;
};

// Formatar data relativa
const formatRelativeTime = (dateStr) => {
  if (!dateStr) return '';

  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now - date;
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  if (diffSec < 60) return 'Agora mesmo';
  if (diffMin < 60) return `Há ${diffMin} min`;
  if (diffHour < 24) return `Há ${diffHour}h`;
  if (diffDay < 7) return `Há ${diffDay} dia${diffDay > 1 ? 's' : ''}`;

  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

// Formatar data completa
const formatFullDate = (dateStr) => {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
};
</script>

<template>
  <div class="relative">
    <!-- Lista vazia -->
    <div
      v-if="activities.length === 0"
      class="text-center py-6 text-sm text-slate-500 dark:text-slate-400"
    >
      <span class="i-lucide-history text-2xl mb-2 block text-slate-300 dark:text-slate-600" />
      Nenhuma atividade registrada
    </div>

    <!-- Timeline -->
    <div v-else class="space-y-4">
      <div
        v-for="(activity, index) in activities"
        :key="activity.id || index"
        class="relative flex gap-3 group"
      >
        <!-- Linha conectora -->
        <div
          v-if="index < activities.length - 1"
          class="absolute left-[15px] top-8 w-0.5 h-[calc(100%+8px)]"
          :class="getActivityConfig(activity.type).lineColor"
        />

        <!-- Ícone -->
        <div
          class="relative z-10 flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center transition-transform group-hover:scale-110"
          :class="getActivityConfig(activity.type).bgColor"
        >
          <span
            :class="[
              getActivityConfig(activity.type).icon,
              getActivityConfig(activity.type).iconColor,
            ]"
            class="text-sm"
          />
        </div>

        <!-- Conteúdo -->
        <div class="flex-1 min-w-0 pb-4">
          <div class="flex items-start justify-between gap-2">
            <div class="min-w-0">
              <p class="text-sm font-medium text-slate-900 dark:text-white">
                {{ activity.type_label || activity.type }}
              </p>
              <p
                v-if="activity.description"
                class="text-sm text-slate-600 dark:text-slate-300 mt-0.5"
              >
                {{ activity.description }}
              </p>
              <p class="text-xs text-slate-400 dark:text-slate-500 mt-1">
                por {{ activity.author || 'Sistema' }}
              </p>
            </div>

            <!-- Timestamp -->
            <div class="flex-shrink-0 text-right">
              <p
                class="text-xs text-slate-500 dark:text-slate-400"
                :title="formatFullDate(activity.created_at)"
              >
                {{ formatRelativeTime(activity.created_at) }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
