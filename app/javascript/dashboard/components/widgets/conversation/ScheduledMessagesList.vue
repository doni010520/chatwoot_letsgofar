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
            {{ truncateMessage(msg.content) }}
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
import { mapGetters } from 'vuex';

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
      loading: false,
    };
  },
  computed: {
    ...mapGetters({
      messages: 'scheduledMessages/getScheduledMessages',
    }),
    scheduledMessages() {
      // Filtrar apenas as mensagens da conversa atual e com status 'pending'
      return this.messages.filter(
        msg =>
          msg.conversation_id === this.conversationId && msg.status === 'pending'
      );
    },
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
        await this.$store.dispatch('scheduledMessages/getAll');
      } catch (error) {
        console.error('Erro ao buscar mensagens agendadas:', error);
      } finally {
        this.loading = false;
      }
    },
    async cancelMessage(id) {
      try {
        await this.$store.dispatch('scheduledMessages/delete', id);
      } catch (error) {
        console.error('Erro ao cancelar mensagem agendada:', error);
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
      if (!message) return '';
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
