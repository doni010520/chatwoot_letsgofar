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
  @apply bg-white dark:bg-slate-700 rounded-lg p-3 shadow-sm border border-slate-200 dark:border-slate-600 cursor-pointer transition-all;

  &:hover {
    @apply shadow-md border-woot-500;
  }

  &__header {
    @apply flex items-center gap-2 mb-2;
  }

  &__contact {
    @apply flex-1 min-w-0;
  }

  &__name {
    @apply block text-sm font-medium text-slate-800 dark:text-slate-100 truncate;
  }

  &__phone {
    @apply block text-xs text-slate-500 dark:text-slate-400 truncate;
  }

  &__value {
    @apply text-sm font-semibold text-green-600 dark:text-green-400 mb-2;
  }

  &__labels {
    @apply flex flex-wrap gap-1 mb-2;
  }

  &__label {
    @apply text-xs text-white px-2 py-0.5 rounded truncate max-w-[100px];
  }

  &__footer {
    @apply flex items-center justify-between;
  }

  &__meta {
    @apply flex items-center gap-2;
  }

  &__status {
    @apply text-xs px-2 py-0.5 rounded;

    &--open {
      @apply bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300;
    }

    &--pending {
      @apply bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300;
    }

    &--resolved {
      @apply bg-slate-100 text-slate-600 dark:bg-slate-600 dark:text-slate-300;
    }

    &--snoozed {
      @apply bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300;
    }
  }

  &__inbox {
    @apply text-xs text-slate-500 dark:text-slate-400;
  }

  &__assignee {
    @apply flex-shrink-0;
  }
}
</style>