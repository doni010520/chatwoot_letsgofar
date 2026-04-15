<template>
  <woot-modal :show="show" :on-close="onClose">
    <div class="p-6">
      <h2 class="text-lg font-medium mb-4">
        {{ isEditing ? 'Editar Mensagem Agendada' : 'Agendar Mensagem' }}
      </h2>

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
          :readonly="!isEditing"
        />
      </div>

      <!-- Arquivos existentes (modo edicao) -->
      <div v-if="existingFiles.length > 0" class="mb-4">
        <label class="block text-sm font-medium mb-2">Arquivos Anexados</label>
        <div class="flex flex-col gap-2">
          <div
            v-for="file in existingFiles"
            :key="file.id"
            class="flex items-center justify-between p-2 bg-n-solid-2 rounded-lg"
          >
            <div class="flex items-center gap-2 min-w-0">
              <span class="file-icon">{{ getFileIcon(file.content_type) }}</span>
              <span class="text-sm truncate">{{ file.filename }}</span>
              <span class="text-xs text-n-slate-10">
                ({{ formatFileSize(file.byte_size) }})
              </span>
            </div>
            <button
              class="remove-file-btn"
              :disabled="removingFileId === file.id"
              @click="removeExistingFile(file.id)"
            >
              {{ removingFileId === file.id ? '...' : 'X' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Upload de novos arquivos -->
      <div class="mb-4">
        <label class="block text-sm font-medium mb-2">Anexar Arquivos</label>
        <div
          class="file-drop-area"
          :class="{ 'file-drop-area--active': isDragging }"
          @dragenter.prevent="isDragging = true"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="onDrop"
          @click="triggerFileInput"
        >
          <input
            ref="fileInput"
            type="file"
            multiple
            class="hidden"
            @change="onFileSelect"
          />
          <p class="text-sm text-n-slate-10">
            Arraste arquivos aqui ou clique para selecionar
          </p>
          <p class="text-xs text-n-slate-9 mt-1">
            Max 300MB por arquivo
          </p>
        </div>
      </div>

      <!-- Preview de novos arquivos selecionados -->
      <div v-if="newFiles.length > 0" class="mb-4">
        <label class="block text-sm font-medium mb-2">
          Novos Arquivos ({{ newFiles.length }})
        </label>
        <div class="flex flex-col gap-2">
          <div
            v-for="(file, index) in newFiles"
            :key="index"
            class="flex items-center justify-between p-2 bg-n-solid-2 rounded-lg"
          >
            <div class="flex items-center gap-2 min-w-0">
              <span class="file-icon">{{ getFileIcon(file.type) }}</span>
              <span class="text-sm truncate">{{ file.name }}</span>
              <span class="text-xs text-n-slate-10">
                ({{ formatFileSize(file.size) }})
              </span>
            </div>
            <button class="remove-file-btn" @click="removeNewFile(index)">
              X
            </button>
          </div>
        </div>
      </div>

      <div v-if="errorMessage" class="error-panel mb-4">
        {{ errorMessage }}
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
          {{ isLoading ? 'Salvando...' : isEditing ? 'Salvar' : 'Agendar' }}
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
    editingMessage: {
      type: Object,
      default: null,
    },
  },
  emits: ['close', 'scheduled'],
  data() {
    return {
      scheduledDateTime: '',
      messageText: '',
      errorMessage: '',
      isLoading: false,
      newFiles: [],
      existingFiles: [],
      isDragging: false,
      removingFileId: null,
    };
  },
  computed: {
    minDateTime() {
      const now = new Date();
      now.setMinutes(now.getMinutes() + 5);
      return now.toISOString().slice(0, 16);
    },
    isEditing() {
      return !!this.editingMessage;
    },
  },
  watch: {
    message(newVal) {
      if (!this.isEditing) {
        this.messageText = newVal;
      }
    },
    show(newVal) {
      if (newVal) {
        this.resetForm();
      }
    },
  },
  methods: {
    resetForm() {
      this.errorMessage = '';
      this.newFiles = [];
      this.isDragging = false;
      this.removingFileId = null;

      if (this.isEditing) {
        this.messageText = this.editingMessage.content;
        const editDate = new Date(this.editingMessage.scheduled_at);
        this.scheduledDateTime = this.toLocalDateTimeString(editDate);
        this.existingFiles = this.editingMessage.files || [];
      } else {
        this.messageText = this.message;
        this.scheduledDateTime = '';
        this.existingFiles = [];
      }
    },
    toLocalDateTimeString(date) {
      const offset = date.getTimezoneOffset();
      const local = new Date(date.getTime() - offset * 60000);
      return local.toISOString().slice(0, 16);
    },
    triggerFileInput() {
      this.$refs.fileInput.click();
    },
    onFileSelect(event) {
      const files = Array.from(event.target.files);
      this.addFiles(files);
      event.target.value = '';
    },
    onDrop(event) {
      this.isDragging = false;
      const files = Array.from(event.dataTransfer.files);
      this.addFiles(files);
    },
    addFiles(files) {
      const maxSize = 300 * 1024 * 1024; // 300MB
      for (const file of files) {
        if (file.size > maxSize) {
          this.errorMessage = `${file.name} excede o tamanho maximo de 300MB`;
          return;
        }
      }
      this.newFiles = [...this.newFiles, ...files];
      this.errorMessage = '';
    },
    removeNewFile(index) {
      this.newFiles.splice(index, 1);
    },
    async removeExistingFile(fileId) {
      this.removingFileId = fileId;
      try {
        await scheduledMessagesAPI.removeFile(
          this.editingMessage.id,
          fileId
        );
        this.existingFiles = this.existingFiles.filter(f => f.id !== fileId);
      } catch (error) {
        console.error('Erro ao remover arquivo:', error);
        this.errorMessage = 'Erro ao remover arquivo. Tente novamente.';
      } finally {
        this.removingFileId = null;
      }
    },
    getFileIcon(contentType) {
      if (!contentType) return '\uD83D\uDCC4';
      if (contentType.startsWith('image/')) return '\uD83D\uDDBC\uFE0F';
      if (contentType.startsWith('video/')) return '\uD83C\uDFA5';
      if (contentType.startsWith('audio/')) return '\uD83C\uDFB5';
      if (contentType.includes('pdf')) return '\uD83D\uDCC4';
      if (contentType.includes('spreadsheet') || contentType.includes('excel'))
        return '\uD83D\uDCCA';
      if (contentType.includes('document') || contentType.includes('word'))
        return '\uD83D\uDCC3';
      return '\uD83D\uDCC1';
    },
    formatFileSize(bytes) {
      if (!bytes) return '0 B';
      const units = ['B', 'KB', 'MB', 'GB'];
      let size = bytes;
      let unitIndex = 0;
      while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
      }
      return `${size.toFixed(1)} ${units[unitIndex]}`;
    },
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
        if (this.isEditing) {
          await scheduledMessagesAPI.update(
            this.editingMessage.id,
            {
              contact_id: this.contactId,
              conversation_id: this.conversationId,
              content: this.messageText,
              scheduled_at: scheduledAt,
            },
            this.newFiles
          );
        } else {
          await scheduledMessagesAPI.create(
            {
              contact_id: this.contactId,
              conversation_id: this.conversationId,
              content: this.messageText,
              scheduled_at: scheduledAt,
            },
            this.newFiles
          );
        }

        this.$emit('scheduled');
        this.onClose();
      } catch (error) {
        console.error('Erro ao agendar mensagem:', error);
        this.errorMessage = `Erro: ${error.response?.data?.errors || error.message}`;
      } finally {
        this.isLoading = false;
      }
    },
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

.file-drop-area {
  border: 2px dashed var(--color-border-light, #d1d5db);
  border-radius: 8px;
  padding: 24px;
  text-align: center;
  cursor: pointer;
  transition: border-color 0.2s, background-color 0.2s;
}

.file-drop-area:hover {
  border-color: var(--color-woot, #1f93ff);
  background-color: rgba(31, 147, 255, 0.04);
}

.file-drop-area--active {
  border-color: var(--color-woot, #1f93ff);
  background-color: rgba(31, 147, 255, 0.08);
}

.file-icon {
  font-size: 16px;
  flex-shrink: 0;
}

.remove-file-btn {
  background: none;
  border: none;
  color: var(--color-text-light, #6b7280);
  cursor: pointer;
  padding: 4px 8px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 4px;
  flex-shrink: 0;
}

.remove-file-btn:hover:not(:disabled) {
  color: #dc2626;
  background: rgba(220, 38, 38, 0.1);
}

.remove-file-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
