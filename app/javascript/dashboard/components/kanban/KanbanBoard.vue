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
        :custom-fields-config="customFieldsConfig"
        @move="handleMove"
        @card-click="handleCardClick"
        @mark-won="handleMarkWon"
        @mark-lost="handleMarkLost"
        @remove="handleRemove"
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
    customFieldsConfig: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['move', 'card-click', 'mark-won', 'mark-lost', 'remove'],
  methods: {
    getColumnItems(column) {
      if (Array.isArray(column.items)) {
        return column.items;
      }
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
    handleMarkWon(payload) {
      this.$emit('mark-won', payload);
    },
    handleMarkLost(payload) {
      this.$emit('mark-lost', payload);
    },
    handleRemove(payload) {
      this.$emit('remove', payload);
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-board {
  flex: 1;
  width: 100%;
  min-height: 100%;
  overflow: visible;
  display: flex;
  flex-direction: column;

  &__columns {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    gap: 16px;
    padding: 20px 24px;
    height: 100%;
    width: 100%;
    overflow-x: visible;
    overflow-y: visible;
    scroll-behavior: smooth;

    // Quando houver muitas colunas, alinha à esquerda para permitir scroll
    &:has(> :nth-child(5)) {
      justify-content: flex-start;
    }
  }
}

// Fallback para browsers que não suportam :has()
@supports not selector(:has(> :nth-child(5))) {
  .kanban-board__columns {
    // Se não suportar :has, centraliza por padrão
    // O overflow-x: auto ainda permite scroll se necessário
    justify-content: center;
  }
}
</style>
