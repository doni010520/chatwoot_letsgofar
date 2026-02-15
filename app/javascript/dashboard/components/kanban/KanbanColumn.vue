<template>
  <div class="kanban-column">
    <KanbanColumnHeader
      :stage="stage"
      :totals="totals"
    />
    <div
      class="kanban-column__cards"
      @dragover.prevent
      @drop="handleDrop"
    >
      <KanbanCard
        v-for="item in items"
        :key="item.id"
        :item="item"
        :item-type="getItemType(item)"
        :custom-fields-config="customFieldsConfig"
        draggable="true"
        @dragstart="handleDragStart($event, item)"
        @click="handleCardClick(item)"
      />
      <div
        v-if="items.length === 0"
        class="kanban-column__empty"
      >
        Nenhum item
      </div>
    </div>
  </div>
</template>

<script>
import KanbanColumnHeader from './KanbanColumnHeader.vue';
import KanbanCard from './KanbanCard.vue';

export default {
  name: 'KanbanColumn',
  components: {
    KanbanColumnHeader,
    KanbanCard,
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
    items: {
      type: Array,
      default: () => [],
    },
    totals: {
      type: Object,
      default: () => ({ count: 0, value: 0 }),
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
  emits: ['move', 'card-click'],
  methods: {
    getItemType(item) {
      if (item.itemType) return item.itemType;
      return item.display_id !== undefined ? 'conversation' : 'contact';
    },
    handleDragStart(event, item) {
      const itemType = this.getItemType(item);
      event.dataTransfer.setData('itemId', item.id);
      event.dataTransfer.setData('itemType', itemType);
      event.dataTransfer.setData('fromStageId', this.stage.id);
    },
    handleDrop(event) {
      const itemId = parseInt(event.dataTransfer.getData('itemId'), 10);
      const itemType = event.dataTransfer.getData('itemType');
      const fromStageId = event.dataTransfer.getData('fromStageId');
      this.$emit('move', {
        itemId,
        itemType,
        fromStageId: fromStageId === 'null' ? null : parseInt(fromStageId, 10),
        toStageId: this.stage.id,
      });
    },
    handleCardClick(item) {
      this.$emit('card-click', {
        item,
        itemType: this.getItemType(item),
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-column {
  @apply flex flex-col bg-slate-50 dark:bg-slate-800 rounded-lg min-w-[300px] max-w-[300px];
  &__cards {
    @apply flex-1 overflow-y-auto p-2 space-y-2;
    min-height: 200px;
  }
  &__empty {
    @apply text-center text-slate-400 dark:text-slate-500 py-8 text-sm;
  }
}
</style>
