<script setup>
const props = defineProps({
  stats: {
    type: Object,
    default: () => ({}),
  },
});

const statCards = [
  { key: 'total', label: 'Total', icon: 'i-lucide-files' },
  { key: 'pending', label: 'Aguardando', icon: 'i-lucide-clock' },
  { key: 'signed', label: 'Assinados', icon: 'i-lucide-check-circle' },
  { key: 'expiring_30_days', label: 'Vencendo', icon: 'i-lucide-alert-triangle' },
  { key: 'this_month', label: 'Este Mês', icon: 'i-lucide-calendar' },
];
</script>

<template>
  <div class="grid grid-cols-5 gap-3">
    <div
      v-for="stat in statCards"
      :key="stat.key"
      class="flex items-center gap-3 p-3 rounded-lg bg-n-solid-2 border border-n-weak"
    >
      <div class="flex items-center justify-center w-9 h-9 rounded-lg bg-n-alpha-3">
        <span :class="stat.icon" class="text-base text-n-slate-11" />
      </div>
      <div>
        <p class="text-xs text-n-slate-11">{{ stat.label }}</p>
        <p class="text-lg font-semibold text-n-slate-12">
          {{ stats[stat.key] || 0 }}
        </p>
      </div>
    </div>
  </div>
</template>
