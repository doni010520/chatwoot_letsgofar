<template>
  <div class="kanban-board">
    <div class="kanban-board__columns">
      <KanbanColumn
        v-for="column in board"
        :key="column.stage.id || 'unassigned'"
        :stage="column.stage"
        :items="getColumnItems(column)"
        :totals="column.totals"
        :pipeline-type="pipelineType"
        @move="handleMove"
        @card-click="handleCardClick"
      />
    </div>
  </div>
</template>

<script>
import KanbanColumn from './KanbanColumn.vue';

export default {
  name: 'KanbanBoard',
  components: {
    KanbanColumn,
  },
  props: {
    board: {
      type: Array,
      default: () => [],
    },
    pipelineType: {
      type: String,
      default: 'conversations',
    },
  },
  emits: ['move', 'card-click'],
  methods: {
    getColumnItems(column) {
      if (Array.isArray(column.items)) {
        return column.items;
      }
      // For pipeline type 'both', items is an object with conversations and contacts
      if (this.pipelineType === 'both') {
        return [
          ...(column.items.conversations || []).map(item => ({ ...item, itemType: 'conversation' })),
          ...(column.items.contacts || []).map(item => ({ ...item, itemType: 'contact' })),
        ];
      }
      return [];
    },
    handleMove(payload) {
      this.$emit('move', payload);
    },
    handleCardClick(payload) {
      this.$emit('card-click', payload);
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-board {
  @apply flex-1 overflow-hidden;

  &__columns {
    @apply flex h-full gap-4 overflow-x-auto p-4;
    scroll-behavior: smooth;
  }
}
</style>