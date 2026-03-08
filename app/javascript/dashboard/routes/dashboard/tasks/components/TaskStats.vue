<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  stats: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['filter-click']);

const { t } = useI18n();

// Grupos de filtros rápidos - visual mais limpo
const quickFilters = computed(() => [
  {
    key: 'overdue',
    label: 'Atrasadas',
    count: props.stats.overdue || 0,
    icon: 'i-lucide-alert-triangle',
    iconBg: 'bg-ruby-100',
    iconColor: 'text-ruby-600',
    countBg: props.stats.overdue > 0 ? 'bg-ruby-100 text-ruby-700' : 'bg-n-alpha-2 text-n-slate-9',
    filter: { due_date: 'overdue', status: 'active' },
  },
  {
    key: 'today',
    label: 'Hoje',
    count: props.stats.due_today || 0,
    icon: 'i-lucide-calendar-check',
    iconBg: 'bg-amber-100',
    iconColor: 'text-amber-600',
    countBg: props.stats.due_today > 0 ? 'bg-amber-100 text-amber-700' : 'bg-n-alpha-2 text-n-slate-9',
    filter: { due_date: 'today', status: 'active' },
  },
  {
    key: 'week',
    label: 'Esta Semana',
    count: props.stats.due_this_week || 0,
    icon: 'i-lucide-calendar-days',
    iconBg: 'bg-blue-100',
    iconColor: 'text-blue-600',
    countBg: props.stats.due_this_week > 0 ? 'bg-blue-100 text-blue-700' : 'bg-n-alpha-2 text-n-slate-9',
    filter: { due_date: 'this_week', status: 'active' },
  },
]);

const assignmentFilters = computed(() => [
  {
    key: 'my_tasks',
    label: 'Minhas Tarefas',
    count: props.stats.my_tasks || 0,
    icon: 'i-lucide-user-check',
    filter: { my_tasks: 'true', status: 'active' },
  },
  {
    key: 'unassigned',
    label: 'Sem Responsável',
    count: props.stats.unassigned || 0,
    icon: 'i-lucide-user-x',
    filter: { unassigned: 'true', status: 'active' },
  },
]);

const statusFilters = computed(() => [
  {
    key: 'pending',
    label: 'Pendente',
    count: props.stats.by_status?.pending || 0,
    dot: 'bg-slate-400',
    filter: { status: 'pending' },
  },
  {
    key: 'in_progress',
    label: 'Em Andamento',
    count: props.stats.by_status?.in_progress || 0,
    dot: 'bg-blue-500',
    filter: { status: 'in_progress' },
  },
  {
    key: 'completed',
    label: 'Concluída',
    count: props.stats.by_status?.completed || 0,
    dot: 'bg-green-500',
    filter: { status: 'completed' },
  },
  {
    key: 'cancelled',
    label: 'Cancelada',
    count: props.stats.by_status?.cancelled || 0,
    dot: 'bg-n-slate-400',
    filter: { status: 'cancelled' },
  },
]);

// Handler
const applyFilter = filter => {
  emit('filter-click', filter);
};
</script>

<template>
  <div class="p-4">
    <!-- Header -->
    <h3 class="text-xs font-bold text-n-slate-10 uppercase tracking-wider mb-4">
      Resumo
    </h3>

    <!-- Filtros rápidos por data - cards visuais -->
    <div class="space-y-2 mb-6">
      <button
        v-for="item in quickFilters"
        :key="item.key"
        class="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-n-alpha-2 transition-all duration-200 group"
        @click="applyFilter(item.filter)"
      >
        <div 
          class="size-9 rounded-lg flex items-center justify-center transition-transform group-hover:scale-110"
          :class="item.iconBg"
        >
          <span :class="[item.icon, item.iconColor]" class="size-4" />
        </div>
        <span class="flex-1 text-sm text-n-slate-11 group-hover:text-n-slate-12 text-left font-medium">
          {{ item.label }}
        </span>
        <span
          class="text-xs font-bold px-2.5 py-1 rounded-full transition-colors"
          :class="item.countBg"
        >
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Divisor -->
    <div class="h-px bg-n-weak my-5" />

    <!-- Filtros por atribuição - mais simples -->
    <div class="space-y-1 mb-6">
      <button
        v-for="item in assignmentFilters"
        :key="item.key"
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-2 transition-colors group"
        @click="applyFilter(item.filter)"
      >
        <div class="flex items-center gap-2.5">
          <span :class="item.icon" class="size-4 text-n-slate-9 group-hover:text-n-slate-11" />
          <span class="text-sm text-n-slate-11 group-hover:text-n-slate-12">
            {{ item.label }}
          </span>
        </div>
        <span class="text-xs font-semibold text-n-slate-9">
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Divisor -->
    <div class="h-px bg-n-weak my-5" />

    <!-- Por status -->
    <h3 class="text-xs font-bold text-n-slate-10 uppercase tracking-wider mb-3">
      Por Status
    </h3>

    <div class="space-y-1">
      <button
        v-for="item in statusFilters"
        :key="item.key"
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-2 transition-colors group"
        @click="applyFilter(item.filter)"
      >
        <div class="flex items-center gap-2.5">
          <span :class="item.dot" class="size-2.5 rounded-full" />
          <span class="text-sm text-n-slate-11 group-hover:text-n-slate-12">
            {{ item.label }}
          </span>
        </div>
        <span class="text-xs font-semibold text-n-slate-9">
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Total ativo - card de destaque -->
    <div class="mt-6 p-4 rounded-xl bg-gradient-to-br from-n-brand/10 to-n-brand/5 border border-n-brand/20">
      <div class="flex items-center justify-between">
        <span class="text-sm font-semibold text-n-slate-11">
          Total Ativas
        </span>
        <span class="text-2xl font-bold text-n-brand">
          {{ stats.total_active || 0 }}
        </span>
      </div>
    </div>
  </div>
</template>
