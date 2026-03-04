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

// Grupos de filtros rápidos
const quickFilters = computed(() => [
  {
    key: 'overdue',
    label: t('TASKS.FILTERS.OVERDUE'),
    count: props.stats.overdue || 0,
    icon: 'i-lucide-alert-circle',
    color: 'text-ruby-11',
    filter: { due_date: 'overdue', status: 'active' },
  },
  {
    key: 'today',
    label: t('TASKS.FILTERS.TODAY'),
    count: props.stats.due_today || 0,
    icon: 'i-lucide-calendar',
    color: 'text-amber-11',
    filter: { due_date: 'today', status: 'active' },
  },
  {
    key: 'week',
    label: t('TASKS.FILTERS.THIS_WEEK'),
    count: props.stats.due_this_week || 0,
    icon: 'i-lucide-calendar-range',
    color: 'text-blue-11',
    filter: { due_date: 'this_week', status: 'active' },
  },
]);

const assignmentFilters = computed(() => [
  {
    key: 'my_tasks',
    label: t('TASKS.FILTERS.MY_TASKS'),
    count: props.stats.my_tasks || 0,
    icon: 'i-lucide-user',
    filter: { my_tasks: 'true', status: 'active' },
  },
  {
    key: 'unassigned',
    label: t('TASKS.FILTERS.UNASSIGNED'),
    count: props.stats.unassigned || 0,
    icon: 'i-lucide-user-x',
    filter: { unassigned: 'true', status: 'active' },
  },
]);

const statusFilters = computed(() => [
  {
    key: 'pending',
    label: t('TASKS.STATUS.PENDING'),
    count: props.stats.by_status?.pending || 0,
    color: 'bg-n-slate-9',
    filter: { status: 'pending' },
  },
  {
    key: 'in_progress',
    label: t('TASKS.STATUS.IN_PROGRESS'),
    count: props.stats.by_status?.in_progress || 0,
    color: 'bg-blue-9',
    filter: { status: 'in_progress' },
  },
  {
    key: 'completed',
    label: t('TASKS.STATUS.COMPLETED'),
    count: props.stats.by_status?.completed || 0,
    color: 'bg-green-9',
    filter: { status: 'completed' },
  },
  {
    key: 'cancelled',
    label: t('TASKS.STATUS.CANCELLED'),
    count: props.stats.by_status?.cancelled || 0,
    color: 'bg-n-slate-7',
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
    <h3 class="text-xs font-semibold text-n-slate-10 uppercase tracking-wide mb-3">
      {{ t('TASKS.STATS.SUMMARY') }}
    </h3>

    <!-- Filtros rápidos por data -->
    <div class="space-y-1 mb-6">
      <button
        v-for="item in quickFilters"
        :key="item.key"
        class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg hover:bg-n-alpha-2 transition-colors group"
        @click="applyFilter(item.filter)"
      >
        <div class="flex items-center gap-2">
          <span :class="[item.icon, item.color]" class="size-4" />
          <span class="text-sm text-n-slate-11 group-hover:text-n-slate-12">
            {{ item.label }}
          </span>
        </div>
        <span
          class="text-xs font-medium px-1.5 py-0.5 rounded-full"
          :class="[
            item.count > 0 ? 'bg-n-alpha-3 text-n-slate-12' : 'text-n-slate-9',
          ]"
        >
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Separador -->
    <hr class="border-n-weak my-4" />

    <!-- Filtros por atribuição -->
    <div class="space-y-1 mb-6">
      <button
        v-for="item in assignmentFilters"
        :key="item.key"
        class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg hover:bg-n-alpha-2 transition-colors group"
        @click="applyFilter(item.filter)"
      >
        <div class="flex items-center gap-2">
          <span :class="item.icon" class="size-4 text-n-slate-9" />
          <span class="text-sm text-n-slate-11 group-hover:text-n-slate-12">
            {{ item.label }}
          </span>
        </div>
        <span
          class="text-xs font-medium px-1.5 py-0.5 rounded-full"
          :class="[
            item.count > 0 ? 'bg-n-alpha-3 text-n-slate-12' : 'text-n-slate-9',
          ]"
        >
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Separador -->
    <hr class="border-n-weak my-4" />

    <!-- Por status -->
    <h3 class="text-xs font-semibold text-n-slate-10 uppercase tracking-wide mb-3">
      {{ t('TASKS.STATS.BY_STATUS') }}
    </h3>

    <div class="space-y-1">
      <button
        v-for="item in statusFilters"
        :key="item.key"
        class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg hover:bg-n-alpha-2 transition-colors group"
        @click="applyFilter(item.filter)"
      >
        <div class="flex items-center gap-2">
          <span :class="item.color" class="size-2 rounded-full" />
          <span class="text-sm text-n-slate-11 group-hover:text-n-slate-12">
            {{ item.label }}
          </span>
        </div>
        <span class="text-xs font-medium text-n-slate-10">
          {{ item.count }}
        </span>
      </button>
    </div>

    <!-- Total ativo -->
    <div class="mt-6 p-3 rounded-lg bg-n-alpha-2">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-n-slate-11">
          {{ t('TASKS.STATS.TOTAL_ACTIVE') }}
        </span>
        <span class="text-lg font-bold text-n-slate-12">
          {{ stats.total_active || 0 }}
        </span>
      </div>
    </div>
  </div>
</template>
