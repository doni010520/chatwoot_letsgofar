<template>
  <div class="kanban-column-header">
    <div class="kanban-column-header__title">
      <span
        class="kanban-column-header__color"
        :style="{ backgroundColor: stage.color || '#9CA3AF' }"
      />
      <span class="kanban-column-header__name">{{ stage.name }}</span>
      <span class="kanban-column-header__count">{{ totals.count || 0 }}</span>
    </div>
    <div
      v-if="totals.value > 0"
      class="kanban-column-header__value"
    >
      {{ formatCurrency(totals.value) }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanColumnHeader',
  props: {
    stage: {
      type: Object,
      required: true,
    },
    totals: {
      type: Object,
      default: () => ({ count: 0, value: 0 }),
    },
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      }).format(value);
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-column-header {
  @apply p-3 border-b border-slate-200 dark:border-slate-700;

  &__title {
    @apply flex items-center gap-2;
  }

  &__color {
    @apply w-3 h-3 rounded-full;
  }

  &__name {
    @apply font-medium text-slate-800 dark:text-slate-100 flex-1 truncate;
  }

  &__count {
    @apply bg-slate-200 dark:bg-slate-600 text-slate-600 dark:text-slate-200 text-xs font-medium px-2 py-0.5 rounded-full;
  }

  &__value {
    @apply text-sm text-green-600 dark:text-green-400 font-medium mt-1;
  }
}
</style>