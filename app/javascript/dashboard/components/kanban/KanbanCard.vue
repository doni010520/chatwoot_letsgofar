<template>
  <div
    class="kanban-card"
    :class="{ 'kanban-card--conversation': itemType === 'conversation' }"
  >
    <div class="kanban-card__header">
      <Thumbnail
        :src="thumbnailSrc"
        :username="contactName"
        size="24px"
      />
      <div class="kanban-card__contact">
        <span class="kanban-card__name">{{ contactName }}</span>
        <span class="kanban-card__phone">{{ contactPhone }}</span>
      </div>
    </div>

    <div
      v-if="item.value > 0"
      class="kanban-card__value"
    >
      {{ formatCurrency(item.value) }}
    </div>

    <div
      v-if="item.labels && item.labels.length > 0"
      class="kanban-card__labels"
    >
      <span
        v-for="label in item.labels.slice(0, 3)"
        :key="label.id"
        class="kanban-card__label"
        :style="{ backgroundColor: label.color }"
      >
        {{ label.title }}
      </span>
    </div>

    <div class="kanban-card__footer">
      <div
        v-if="itemType === 'conversation'"
        class="kanban-card__meta"
      >
        <span
          class="kanban-card__status"
          :class="`kanban-card__status--${item.status}`"
        >
          {{ statusLabel }}
        </span>
        <span
          v-if="item.inbox"
          class="kanban-card__inbox"
        >
          {{ item.inbox.name }}
        </span>
      </div>
      <div
        v-if="item.assignee"
        class="kanban-card__assignee"
      >
        <Thumbnail
          :src="item.assignee.thumbnail"
          :username="item.assignee.name"
          size="20px"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'KanbanCard',
  components: {
    Thumbnail,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    itemType: {
      type: String,
      default: 'conversation',
    },
  },
  computed: {
    contactName() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.name || 'Sem nome';
      }
      return this.item.name || 'Sem nome';
    },
    contactPhone() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.phone_number || this.item.contact?.email || '';
      }
      return this.item.phone_number || this.item.email || '';
    },
    thumbnailSrc() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.thumbnail || '';
      }
      return this.item.thumbnail || '';
    },
    statusLabel() {
      const statuses = {
        open: 'Aberto',
        resolved: 'Resolvido',
        pending: 'Pendente',
        snoozed: 'Adiado',
      };
      return statuses[this.item.status] || this.item.status;
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
.kanban-card {
  background-color: var(--white);
  border-radius: var(--border-radius-normal);
  padding: var(--space-small);
  box-shadow: var(--shadow-small);
  border: 1px solid var(--color-border-light);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    box-shadow: var(--shadow-medium);
    border-color: var(--w-500);
  }

  &__header {
    display: flex;
    align-items: center;
    gap: var(--space-small);
    margin-bottom: var(--space-small);
  }

  &__contact {
    flex: 1;
    min-width: 0;
  }

  &__name {
    display: block;
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    color: var(--color-body);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__phone {
    display: block;
    font-size: var(--font-size-mini);
    color: var(--s-600);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__value {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
    color: var(--g-500);
    margin-bottom: var(--space-small);
  }

  &__labels {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-micro);
    margin-bottom: var(--space-small);
  }

  &__label {
    font-size: var(--font-size-micro);
    color: var(--white);
    padding: var(--space-micro) var(--space-small);
    border-radius: var(--border-radius-small);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100px;
  }

  &__footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  &__meta {
    display: flex;
    align-items: center;
    gap: var(--space-small);
  }

  &__status {
    font-size: var(--font-size-micro);
    padding: var(--space-micro) var(--space-small);
    border-radius: var(--border-radius-small);

    &--open {
      background-color: var(--g-100);
      color: var(--g-700);
    }

    &--pending {
      background-color: var(--y-100);
      color: var(--y-700);
    }

    &--resolved {
      background-color: var(--s-100);
      color: var(--s-600);
    }

    &--snoozed {
      background-color: var(--w-100);
      color: var(--w-700);
    }
  }

  &__inbox {
    font-size: var(--font-size-micro);
    color: var(--s-600);
  }

  &__assignee {
    flex-shrink: 0;
  }
}
</style>
