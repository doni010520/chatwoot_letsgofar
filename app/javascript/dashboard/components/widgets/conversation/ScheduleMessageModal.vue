<template>
  <woot-modal :show="show" :on-close="onClose">
    <div class="p-6">
      <h2 class="text-lg font-medium mb-4">Agendar Mensagem</h2>
      
      <div class="mb-4">
        <label class="block text-sm font-medium mb-2">Data e Hora</label>
        <input
          v-model="scheduledDateTime"
          type="datetime-local"
          class="w-full border border-n-weak rounded-lg p-2 bg-n-solid-1"
          :min="minDateTime"
        />
      </div>

      <div class="mb-4">
        <label class="block text-sm font-medium mb-2">Mensagem</label>
        <textarea
          v-model="messageText"
          class="w-full border border-n-weak rounded-lg p-2 bg-n-solid-1 min-h-[100px]"
          readonly
        />
      </div>

      <div v-if="errorMessage" class="error-panel mb-4">
        ❌ {{ errorMessage }}
      </div>

      <div class="flex justify-end gap-2">
        <woot-button variant="clear" class="cursor-pointer" @click="onClose">
          Cancelar
        </woot-button>
        <woot-button 
          class="cursor-pointer" 
          :disabled="!scheduledDateTime || isLoading" 
          @click="onSchedule"
        >
          {{ isLoading ? '⏳ Agendando...' : 'Agendar' }}
        </woot-button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import scheduledMessagesAPI from 'dashboard/api/scheduledMessages';

export default {
  name: 'ScheduleMessageModal',
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    message: {
      type: String,
      default: '',
    },
    conversationId: {
      type: Number,
      required: true,
    },
    contactId: {
      type: Number,
      required: true,
    },
  },
  emits: ['close', 'scheduled'],
  data() {
    return {
      scheduledDateTime: '',
      messageText: '',
      errorMessage: '',
      isLoading: false,
    };
  },
  computed: {
    minDateTime() {
      const now = new Date();
      now.setMinutes(now.getMinutes() + 5);
      return now.toISOString().slice(0, 16);
    },
  },
  watch: {
    message(newVal) {
      this.messageText = newVal;
    },
    show(newVal) {
      if (newVal) {
        this.messageText = this.message;
        this.scheduledDateTime = '';
        this.errorMessage = '';
      }
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async onSchedule() {
      if (!this.scheduledDateTime) {
        this.errorMessage = 'Selecione data e hora!';
        return;
      }

      this.isLoading = true;
      this.errorMessage = '';

      const scheduledDate = new Date(this.scheduledDateTime);
      const scheduledAt = scheduledDate.toISOString();

      try {
        await scheduledMessagesAPI.create({
          contact_id: this.contactId,
          conversation_id: this.conversationId,
          content: this.messageText,
          scheduled_at: scheduledAt,
        });

        this.$emit('scheduled');
        this.onClose();
      } catch (error) {
        console.error('Erro ao agendar mensagem:', error);
        this.errorMessage = `Erro: ${error.response?.data?.errors || error.message}`;
      } finally {
        this.isLoading = false;
      }
    }
  },
};
</script>

<style scoped>
.error-panel {
  background: #fee;
  border: 1px solid #fcc;
  padding: 12px;
  border-radius: 8px;
  color: #c00;
  font-size: 14px;
}
</style>
