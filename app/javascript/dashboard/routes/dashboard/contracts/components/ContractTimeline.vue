<script setup>
defineProps({
  activities: { type: Array, default: () => [] },
});

const typeConfig = {
  created: { icon: 'i-lucide-plus-circle', color: 'text-n-blue-11' },
  edited: { icon: 'i-lucide-pencil', color: 'text-n-slate-11' },
  sent: { icon: 'i-lucide-send', color: 'text-n-blue-11' },
  viewed: { icon: 'i-lucide-eye', color: 'text-n-slate-11' },
  signed: { icon: 'i-lucide-check-circle', color: 'text-n-teal-11' },
  refused: { icon: 'i-lucide-x-circle', color: 'text-n-ruby-11' },
  expired: { icon: 'i-lucide-clock', color: 'text-n-amber-11' },
  cancelled: { icon: 'i-lucide-ban', color: 'text-n-ruby-11' },
  completed: { icon: 'i-lucide-check-circle-2', color: 'text-n-teal-11' },
  reminder_sent: { icon: 'i-lucide-bell', color: 'text-n-amber-11' },
};

const getConfig = type => typeConfig[type] || { icon: 'i-lucide-activity', color: 'text-n-slate-11' };

const formatDate = dateStr => {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return `${d.toLocaleDateString('pt-BR')} ${d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}`;
};
</script>

<template>
  <div class="flex flex-col gap-0">
    <div
      v-for="(activity, index) in activities"
      :key="activity.id || index"
      class="flex gap-3 pb-4 last:pb-0"
    >
      <div class="flex flex-col items-center">
        <div class="flex items-center justify-center w-7 h-7 rounded-full bg-n-alpha-3">
          <span :class="[getConfig(activity.type).icon, getConfig(activity.type).color]" class="text-sm" />
        </div>
        <div v-if="index < activities.length - 1" class="flex-1 w-px bg-n-weak mt-1" />
      </div>
      <div class="flex-1 pb-2">
        <p class="text-sm text-n-slate-12">
          {{ activity.description || activity.type_label || activity.type }}
        </p>
        <div class="flex items-center gap-2 mt-0.5">
          <span v-if="activity.author" class="text-xs text-n-slate-11">{{ activity.author }}</span>
          <span class="text-xs text-n-slate-10">{{ formatDate(activity.created_at) }}</span>
        </div>
      </div>
    </div>

    <p v-if="!activities || activities.length === 0" class="text-sm text-n-slate-11 text-center py-4">
      Nenhuma atividade registrada.
    </p>
  </div>
</template>
