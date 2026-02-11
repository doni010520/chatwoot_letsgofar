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

      <div class="flex justify-end gap-2">
        <woot-button variant="clear" @click="onClose">
          Cancelar
        </woot-button>
        <woot-button @click="onSchedule" :disabled="!scheduledDateTime">
          Agendar
        </woot-button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
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
    accountId: {
      type: Number,
      required: true,
    },
    inboxId: {
      type: Number,
      required: true,
    },
  },
  emits: ['close', 'scheduled'],
  data() {
    return {
      scheduledDateTime: '',
      messageText: '',
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
      }
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async onSchedule() {
      if (!this.scheduledDateTime) return;

      const webhookUrl = 'SEU_WEBHOOK_N8N_AQUI'; // <-- TROCAR PELA URL DO SEU N8N

      const payload = {
        conversation_id: this.conversationId,
        account_id: this.accountId,
        inbox_id: this.inboxId,
        message: this.messageText,
        scheduled_at: new Date(this.scheduledDateTime).toISOString(),
      };

      try {
        await fetch(webhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });

        this.$emit('scheduled');
        this.onClose();
      } catch (error) {
        console.error('Erro ao agendar mensagem:', error);
      }
    },
  },
};
</script>
