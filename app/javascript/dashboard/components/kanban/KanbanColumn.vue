<template>
  <div 
    class="kanban-column"
    :class="{ 'kanban-column--drag-over': isDragOver }"
    @dragover.prevent="onDragOver"
    @dragleave="onDragLeave"
    @drop="handleDrop"
  >
    <KanbanColumnHeader
      :stage="stage"
      :totals="totals"
    />
    <div class="kanban-column__cards">
      <KanbanCard
        v-for="item in items"
        :key="item.id"
        :item="item"
        :item-type="getItemType(item)"
        :custom-fields-config="customFieldsConfig"
        @dragstart="handleDragStart($event, item)"
        @click="handleCardClick(item)"
        @mark-won="handleMarkWon"
        @mark-lost="handleMarkLost"
        @remove="handleRemove"
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
  emits: ['move', 'card-click', 'mark-won', 'mark-lost', 'remove'],
  data() {
    return {
      isDragOver: false,
    };
  },
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
      event.dataTransfer.effectAllowed = 'move';
    },
    onDragOver(event) {
      event.preventDefault();
      this.isDragOver = true;
    },
    onDragLeave() {
      this.isDragOver = false;
    },
    handleDrop(event) {
      this.isDragOver = false;
      const itemId = parseInt(event.dataTransfer.getData('itemId'), 10);
      const itemType = event.dataTransfer.getData('itemType');
      const fromStageId = event.dataTransfer.getData('fromStageId');
      
      // Não emite se soltar na mesma coluna
      if (parseInt(fromStageId, 10) === this.stage.id) {
        return;
      }
      
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
.kanban-column {
  @apply flex flex-col bg-slate-50 dark:bg-slate-800 rounded-lg min-w-[300px] max-w-[300px];
  transition: all 0.2s ease;
  border: 2px solid transparent;
  max-height: 100%;
  
  &--drag-over {
    background-color: rgba(59, 130, 246, 0.1);
    border-color: #3b82f6;
    border-style: dashed;
  }
  
  &__cards {
    @apply flex-1 overflow-y-auto p-2 space-y-2;
    min-height: 200px;
    transition: background-color 0.2s;
  }
  
  &__empty {
    @apply text-center text-slate-400 dark:text-slate-500 py-8 text-sm;
  }
}
</style>
