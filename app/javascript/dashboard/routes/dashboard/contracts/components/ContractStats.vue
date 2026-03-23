<script setup>
import { computed } from 'vue';

const props = defineProps({
  stats: {
    type: Object,
    default: () => ({}),
  },
});

// Cards de estatísticas
const statCards = computed(() => [
  {
    key: 'total',
    label: 'Total',
    value: props.stats.total || 0,
    icon: 'i-lucide-files',
    bgColor: 'bg-slate-100 dark:bg-slate-800',
    iconColor: 'text-slate-600 dark:text-slate-400',
    valueColor: 'text-slate-900 dark:text-white',
  },
  {
    key: 'pending',
    label: 'Aguardando',
    value: props.stats.pending || 0,
    icon: 'i-lucide-clock',
    bgColor: 'bg-amber-50 dark:bg-amber-900/20',
    iconColor: 'text-amber-600 dark:text-amber-500',
    valueColor: 'text-amber-700 dark:text-amber-400',
  },
  {
    key: 'signed',
    label: 'Assinados',
    value: props.stats.signed || 0,
    icon: 'i-lucide-check-circle',
    bgColor: 'bg-green-50 dark:bg-green-900/20',
    iconColor: 'text-green-600 dark:text-green-500',
    valueColor: 'text-green-700 dark:text-green-400',
  },
  {
    key: 'expiring',
    label: 'Vencendo',
    value: props.stats.expiring_30_days || 0,
    icon: 'i-lucide-alert-triangle',
    bgColor: 'bg-orange-50 dark:bg-orange-900/20',
    iconColor: 'text-orange-600 dark:text-orange-500',
    valueColor: 'text-orange-700 dark:text-orange-400',
  },
  {
    key: 'this_month',
    label: 'Este Mês',
    value: props.stats.this_month || 0,
    icon: 'i-lucide-calendar',
    bgColor: 'bg-rose-50 dark:bg-rose-900/20',
    iconColor: 'text-rose-600 dark:text-rose-500',
    valueColor: 'text-rose-700 dark:text-rose-400',
  },
]);
</script>

<template>
  <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
    <div
      v-for="stat in statCards"
      :key="stat.key"
      class="group relative overflow-hidden rounded-2xl p-5 transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5"
      :class="stat.bgColor"
    >
      <!-- Decoração de fundo -->
      <div
        class="absolute -right-4 -top-4 w-20 h-20 rounded-full opacity-10 transition-transform group-hover:scale-150 duration-500"
        :class="stat.iconColor.replace('text-', 'bg-')"
      />

      <div class="relative flex items-start justify-between">
        <div>
          <p class="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">
            {{ stat.label }}
          </p>
          <p class="text-3xl font-bold" :class="stat.valueColor">
            {{ stat.value }}
          </p>
        </div>
        <div
          class="w-12 h-12 rounded-xl flex items-center justify-center transition-transform group-hover:scale-110 duration-300"
          :class="stat.bgColor"
        >
          <span :class="[stat.icon, stat.iconColor]" class="text-2xl" />
        </div>
      </div>

      <!-- Barra de progresso sutil para "signed" -->
      <div
        v-if="stat.key === 'signed' && stats.total > 0"
        class="mt-3 pt-3 border-t border-green-200 dark:border-green-800"
      >
        <div class="flex items-center justify-between text-xs mb-1">
          <span class="text-green-600 dark:text-green-400">Taxa de assinatura</span>
          <span class="font-medium text-green-700 dark:text-green-300">
            {{ Math.round((stats.signed / stats.total) * 100) }}%
          </span>
        </div>
        <div class="h-1.5 bg-green-200 dark:bg-green-800 rounded-full overflow-hidden">
          <div
            class="h-full bg-green-500 rounded-full transition-all duration-1000"
            :style="{ width: `${(stats.signed / stats.total) * 100}%` }"
          />
        </div>
      </div>

      <!-- Info extra para "expiring" -->
      <div
        v-if="stat.key === 'expiring' && stats.expired_plans"
        class="mt-3 pt-3 border-t border-orange-200 dark:border-orange-800"
      >
        <div class="flex items-center gap-1.5 text-xs text-orange-600 dark:text-orange-400">
          <span class="i-lucide-clock" />
          <span>{{ stats.expired_plans }} com plano expirado</span>
        </div>
      </div>

      <!-- Info extra para "this_month" -->
      <div
        v-if="stat.key === 'this_month' && stats.signed_this_month !== undefined"
        class="mt-3 pt-3 border-t border-rose-200 dark:border-rose-800"
      >
        <div class="flex items-center gap-1.5 text-xs text-rose-600 dark:text-rose-400">
          <span class="i-lucide-trending-up" />
          <span>{{ stats.signed_this_month || 0 }} assinados este mês</span>
        </div>
      </div>
    </div>
  </div>
</template>
