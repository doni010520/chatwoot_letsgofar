<template>
  <div v-if="scheduledMessages.length > 0" class="scheduled-messages">
    <div class="scheduled-messages__header">
      <h4 class="text-sm font-medium text-n-slate-12">
        Mensagens Agendadas ({{ scheduledMessages.length }})
      </h4>
    </div>
    <div class="scheduled-messages__list">
      <div
        v-for="msg in scheduledMessages"
        :key="msg.id"
        class="scheduled-message-item"
      >
        <div class="scheduled-message-item__content">
          <span class="scheduled-message-item__time">
            {{ formatDate(msg.scheduled_at) }}
          </span>
          <p class="scheduled-message-item__text">
            {{ truncateMessage(msg.message) }}
          </p>
        </div>
        <button
          class="scheduled-message-item__cancel"
          @click="cancelMessage(msg.id)"
        >
          ✕
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ScheduledMessagesList',
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      scheduledMessages: [],
      loading: false,
    };
  },
  watch: {
    conversationId: {
      immediate: true,
      handler(newId) {
        if (newId) {
          this.fetchScheduledMessages();
        }
      },
    },
  },
  methods: {
    async fetchScheduledMessages() {
      this.loading = true;
      try {
        const response = await fetch(
          `https://benitech-n8n.x3t6qy.easypanel.host/webhook/chatwoot-scheduled-list?conversation_id=${this.conversationId}`
        );
        const data = await response.json();
        this.scheduledMessages = Array.isArray(data) ? data : [];
      } catch (error) {
        console.error('Erro ao buscar mensagens agendadas:', error);
        this.scheduledMessages = [];
      } finally {
        this.loading = false;
      }
    },
    async cancelMessage(id) {
      try {
        await fetch(
          'https://benitech-n8n.x3t6qy.easypanel.host/webhook/chatwoot-scheduled-cancel',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id }),
          }
        );
        this.fetchScheduledMessages();
      } catch (error) {
        console.error('Erro ao cancelar mensagem:', error);
      }
    },
    formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      });
    },
    truncateMessage(message) {
      return message.length > 50 ? message.substring(0, 50) + '...' : message;
    },
  },
};
</script>

<style scoped>
.scheduled-messages {
  padding: 12px;
  border-bottom: 1px solid var(--color-border-light);
}

.scheduled-messages__header {
  margin-bottom: 8px;
}

.scheduled-messages__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.scheduled-message-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px;
  background: var(--color-background-light);
  border-radius: 8px;
}

.scheduled-message-item__content {
  flex: 1;
}

.scheduled-message-item__time {
  font-size: 12px;
  color: var(--color-text-light);
}

.scheduled-message-item__text {
  font-size: 13px;
  margin: 4px 0 0 0;
}

.scheduled-message-item__cancel {
  background: none;
  border: none;
  color: var(--color-text-light);
  cursor: pointer;
  padding: 4px 8px;
}

.scheduled-message-item__cancel:hover {
  color: red;
}
</style>
