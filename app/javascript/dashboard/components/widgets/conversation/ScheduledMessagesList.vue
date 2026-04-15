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
        @click="openEditModal(msg)"
      >
        <div class="scheduled-message-item__content">
          <div class="scheduled-message-item__meta">
            <span class="scheduled-message-item__time">
              {{ formatDate(msg.scheduled_at) }}
            </span>
            <span
              v-if="msg.files && msg.files.length > 0"
              class="scheduled-message-item__attachment-badge"
              :title="msg.files.length + ' arquivo(s) anexado(s)'"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path
                  d="M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48"
                />
              </svg>
              <span class="text-xs">{{ msg.files.length }}</span>
            </span>
          </div>
          <p class="scheduled-message-item__text">
            {{ truncateMessage(msg.content) }}
          </p>
        </div>
        <button
          class="scheduled-message-item__cancel"
          :disabled="cancellingId === msg.id"
          @click.stop="cancelMessage(msg.id)"
        >
          {{ cancellingId === msg.id ? '...' : 'X' }}
        </button>
      </div>
    </div>

    <ScheduleMessageModal
      :show="showEditModal"
      :message="editingMessage ? editingMessage.content : ''"
      :conversation-id="conversationId"
      :contact-id="editingMessage ? editingMessage.contact.id : 0"
      :editing-message="editingMessage"
      @close="closeEditModal"
      @scheduled="onMessageUpdated"
    />
  </div>
</template>

<script>
import scheduledMessagesAPI from 'dashboard/api/scheduledMessages';
import ScheduleMessageModal from './ScheduleMessageModal.vue';

export default {
  name: 'ScheduledMessagesList',
  components: {
    ScheduleMessageModal,
  },
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
      cancellingId: null,
      showEditModal: false,
      editingMessage: null,
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
        const response = await scheduledMessagesAPI.getAll({
          conversation_id: this.conversationId,
        });
        this.scheduledMessages = response.data || [];
      } catch (error) {
        console.error('Erro ao buscar mensagens agendadas:', error);
        this.scheduledMessages = [];
      } finally {
        this.loading = false;
      }
    },
    async cancelMessage(id) {
      if (!confirm('Deseja realmente cancelar esta mensagem agendada?')) {
        return;
      }

      this.cancellingId = id;

      try {
        await scheduledMessagesAPI.delete(id);
        this.fetchScheduledMessages();
      } catch (error) {
        console.error('Erro ao cancelar mensagem:', error);
        alert('Erro ao cancelar mensagem. Tente novamente.');
      } finally {
        this.cancellingId = null;
      }
    },
    openEditModal(msg) {
      this.editingMessage = msg;
      this.showEditModal = true;
    },
    closeEditModal() {
      this.showEditModal = false;
      this.editingMessage = null;
    },
    onMessageUpdated() {
      this.closeEditModal();
      this.fetchScheduledMessages();
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
  cursor: pointer;
  transition: background-color 0.15s;
}

.scheduled-message-item:hover {
  background: var(--color-background-hover, rgba(0, 0, 0, 0.04));
}

.scheduled-message-item__content {
  flex: 1;
  min-width: 0;
}

.scheduled-message-item__meta {
  display: flex;
  align-items: center;
  gap: 6px;
}

.scheduled-message-item__time {
  font-size: 12px;
  color: var(--color-text-light);
}

.scheduled-message-item__attachment-badge {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  color: var(--color-woot, #1f93ff);
  opacity: 0.8;
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
  font-size: 12px;
  font-weight: 600;
  border-radius: 4px;
}

.scheduled-message-item__cancel:hover:not(:disabled) {
  color: red;
  background: rgba(220, 38, 38, 0.1);
}

.scheduled-message-item__cancel:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
