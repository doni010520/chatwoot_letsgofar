<template>
  <div class="kanban-card" @click="$emit('click')">
    <!-- Header com foto e info do contato -->
    <div class="kanban-card__header">
      <div class="kanban-card__avatar">
        <img
          v-if="contactThumbnail"
          :src="contactThumbnail"
          :alt="contactName"
          class="kanban-card__avatar-img"
        />
        <span v-else class="kanban-card__avatar-initials">
          {{ getInitials(contactName) }}
        </span>
      </div>
      <div class="kanban-card__info">
        <span class="kanban-card__name">{{ contactName }}</span>
        <span class="kanban-card__phone">{{ contactPhone }}</span>
      </div>
    </div>

    <!-- ID da conversa -->
    <div v-if="itemType === 'conversation'" class="kanban-card__id">
      #{{ item.display_id }}
    </div>

    <!-- Status e tempo -->
    <div class="kanban-card__footer">
      <span
        class="kanban-card__status"
        :class="`kanban-card__status--${item.status}`"
      >
        {{ statusLabel }}
      </span>
      <span v-if="timeAgo" class="kanban-card__time">
        {{ timeAgo }}
      </span>
    </div>

    <!-- Assignee -->
    <div v-if="item.assignee" class="kanban-card__assignee">
      <span class="kanban-card__assignee-label">Atribuído:</span>
      <span class="kanban-card__assignee-name">{{ item.assignee.name }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanCard',
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
  emits: ['click'],
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
    contactThumbnail() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.thumbnail || this.item.contact?.avatar_url || null;
      }
      return this.item.thumbnail || this.item.avatar_url || null;
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
    timeAgo() {
      const date = this.item.last_activity_at;
      if (!date) return null;
      
      const now = new Date();
      const past = new Date(date);
      const diffMs = now - past;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return 'Agora';
      if (diffMins < 60) return `${diffMins}min`;
      if (diffHours < 24) return `${diffHours}h`;
      if (diffDays < 7) return `${diffDays}d`;
      return past.toLocaleDateString('pt-BR');
    },
  },
  methods: {
    getInitials(name) {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .substring(0, 2)
        .toUpperCase();
    },
  },
};
</script>

<style scoped>
.kanban-card {
  background-color: #ffffff;
  border-radius: 8px;
  padding: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e7eb;
  cursor: pointer;
  transition: all 0.2s ease;
}

.kanban-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  border-color: #3b82f6;
  transform: translateY(-1px);
}

.kanban-card__header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.kanban-card__avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  flex-shrink: 0;
  overflow: hidden;
  background-color: #3b82f6;
  display: flex;
  align-items: center;
  justify-content: center;
}

.kanban-card__avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.kanban-card__avatar-initials {
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
}

.kanban-card__info {
  flex: 1;
  min-width: 0;
}

.kanban-card__name {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.kanban-card__phone {
  display: block;
  font-size: 12px;
  color: #6b7280;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-top: 2px;
}

.kanban-card__id {
  font-size: 11px;
  color: #9ca3af;
  margin-bottom: 8px;
}

.kanban-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.kanban-card__status {
  font-size: 11px;
  font-weight: 500;
  padding: 3px 8px;
  border-radius: 4px;
}

.kanban-card__status--open {
  background-color: #d1fae5;
  color: #065f46;
}

.kanban-card__status--pending {
  background-color: #fef3c7;
  color: #92400e;
}

.kanban-card__status--resolved {
  background-color: #e5e7eb;
  color: #4b5563;
}

.kanban-card__status--snoozed {
  background-color: #dbeafe;
  color: #1e40af;
}

.kanban-card__time {
  font-size: 11px;
  color: #9ca3af;
}

.kanban-card__assignee {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #6b7280;
  padding-top: 6px;
  border-top: 1px solid #f3f4f6;
}

.kanban-card__assignee-label {
  color: #9ca3af;
}

.kanban-card__assignee-name {
  color: #4b5563;
  font-weight: 500;
}
</style>
