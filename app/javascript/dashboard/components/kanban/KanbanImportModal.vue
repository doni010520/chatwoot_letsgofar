<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-container">
      <header class="modal-header">
        <h2>Importar Leads</h2>
        <button class="modal-close" @click="$emit('close')">×</button>
      </header>

      <div class="modal-body">
        <!-- Step 1: Selecionar estágio -->
        <div class="form-group">
          <label>Estágio de destino *</label>
          <select v-model="selectedStageId" class="form-select">
            <option value="">Selecione o estágio...</option>
            <option
              v-for="stage in stages"
              :key="stage.id"
              :value="stage.id"
            >
              {{ stage.name }}
            </option>
          </select>
        </div>

        <!-- Step 2: Upload de arquivo -->
        <div class="form-group">
          <label>Arquivo CSV *</label>
          <div
            class="upload-area"
            :class="{ 'upload-area--dragover': isDragOver }"
            @dragover.prevent="isDragOver = true"
            @dragleave="isDragOver = false"
            @drop.prevent="handleDrop"
            @click="triggerFileInput"
          >
            <input
              ref="fileInput"
              type="file"
              accept=".csv,.txt"
              hidden
              @change="handleFileSelect"
            />
            <div v-if="!selectedFile" class="upload-placeholder">
              <span class="upload-icon">📄</span>
              <p>Arraste um arquivo CSV ou clique para selecionar</p>
              <span class="upload-hint">Máximo 5MB, formato CSV com separador ; ou ,</span>
            </div>
            <div v-else class="upload-selected">
              <span class="file-icon">📄</span>
              <span class="file-name">{{ selectedFile.name }}</span>
              <button class="file-remove" @click.stop="removeFile">×</button>
            </div>
          </div>
        </div>

        <!-- Template download -->
        <div class="template-section">
          <p>Não tem um arquivo? Baixe o template com os campos do pipeline:</p>
          <button class="template-btn" :disabled="isDownloading" @click="downloadTemplate">
            <span>📥</span>
            {{ isDownloading ? 'Baixando...' : 'Baixar Template' }}
          </button>
        </div>

        <!-- Resultados -->
        <div v-if="importResult" class="import-result" :class="resultClass">
          <div class="result-header">
            <span v-if="importResult.success_count > 0" class="result-icon">✅</span>
            <span v-else class="result-icon">⚠️</span>
            <span>{{ importResult.message }}</span>
          </div>
          <div v-if="importResult.errors && importResult.errors.length > 0" class="result-errors">
            <p>Erros encontrados:</p>
            <ul>
              <li v-for="(err, idx) in importResult.errors" :key="idx">
                Linha {{ err.row }}: {{ err.error }}
              </li>
            </ul>
          </div>
        </div>
      </div>

      <footer class="modal-footer">
        <button class="btn-cancel" @click="$emit('close')">
          Cancelar
        </button>
        <button
          class="btn-import"
          :disabled="!canImport || isImporting"
          @click="importFile"
        >
          {{ isImporting ? 'Importando...' : 'Importar' }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script>
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanImportModal',
  props: {
    pipelineId: {
      type: [Number, String],
      required: true,
    },
    stages: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['close', 'imported'],
  data() {
    return {
      selectedStageId: '',
      selectedFile: null,
      isDragOver: false,
      isImporting: false,
      isDownloading: false,
      importResult: null,
    };
  },
  computed: {
    accountId() {
      return this.$route.params.accountId;
    },
    canImport() {
      return this.selectedStageId && this.selectedFile;
    },
    resultClass() {
      if (!this.importResult) return '';
      return this.importResult.error_count > 0 ? 'result--warning' : 'result--success';
    },
  },
  methods: {
    triggerFileInput() {
      this.$refs.fileInput.click();
    },
    handleFileSelect(event) {
      const file = event.target.files[0];
      this.validateAndSetFile(file);
    },
    handleDrop(event) {
      this.isDragOver = false;
      const file = event.dataTransfer.files[0];
      this.validateAndSetFile(file);
    },
    validateAndSetFile(file) {
      if (!file) return;

      // Validar tamanho (5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('Arquivo muito grande. Máximo permitido: 5MB');
        return;
      }

      // Validar extensão
      const ext = file.name.split('.').pop().toLowerCase();
      if (!['csv', 'txt'].includes(ext)) {
        alert('Formato inválido. Use arquivos CSV ou TXT.');
        return;
      }

      this.selectedFile = file;
      this.importResult = null;
    },
    removeFile() {
      this.selectedFile = null;
      this.importResult = null;
      if (this.$refs.fileInput) {
        this.$refs.fileInput.value = '';
      }
    },
    async downloadTemplate() {
      this.isDownloading = true;
      try {
        const response = await KanbanAPI.downloadImportTemplate(
          this.accountId,
          this.pipelineId
        );
        
        const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', 'template_importacao.csv');
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      } catch (error) {
        console.error('Erro ao baixar template:', error);
        alert('Erro ao baixar template');
      } finally {
        this.isDownloading = false;
      }
    },
    async importFile() {
      if (!this.canImport) return;

      this.isImporting = true;
      this.importResult = null;

      try {
        const response = await KanbanAPI.importLeads(
          this.accountId,
          this.pipelineId,
          this.selectedFile,
          this.selectedStageId
        );

        this.importResult = response.data;

        if (response.data.success_count > 0) {
          this.$emit('imported');
        }
      } catch (error) {
        console.error('Erro na importação:', error);
        this.importResult = {
          message: error.response?.data?.error || 'Erro ao importar arquivo',
          success_count: 0,
          error_count: 1,
        };
      } finally {
        this.isImporting = false;
      }
    },
  },
};
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-container {
  background-color: white;
  border-radius: 12px;
  width: 100%;
  max-width: 500px;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h2 {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.modal-close:hover {
  color: #1f2937;
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  margin-bottom: 6px;
}

.form-select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  color: #1f2937;
  background-color: white;
  cursor: pointer;
}

.form-select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.upload-area {
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  padding: 24px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.upload-area:hover {
  border-color: #3b82f6;
  background-color: #f9fafb;
}

.upload-area--dragover {
  border-color: #3b82f6;
  background-color: #eff6ff;
}

.upload-placeholder {
  color: #6b7280;
}

.upload-icon {
  font-size: 32px;
  display: block;
  margin-bottom: 8px;
}

.upload-placeholder p {
  margin: 0 0 4px 0;
  font-size: 14px;
}

.upload-hint {
  font-size: 12px;
  color: #9ca3af;
}

.upload-selected {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.file-icon {
  font-size: 20px;
}

.file-name {
  font-size: 14px;
  color: #1f2937;
  font-weight: 500;
}

.file-remove {
  background: none;
  border: none;
  font-size: 18px;
  color: #ef4444;
  cursor: pointer;
  padding: 0 4px;
}

.template-section {
  padding: 16px;
  background-color: #f9fafb;
  border-radius: 8px;
  text-align: center;
}

.template-section p {
  font-size: 13px;
  color: #6b7280;
  margin: 0 0 12px 0;
}

.template-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background-color: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 13px;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.template-btn:hover:not(:disabled) {
  background-color: #f3f4f6;
  border-color: #9ca3af;
}

.template-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.import-result {
  margin-top: 20px;
  padding: 16px;
  border-radius: 8px;
}

.result--success {
  background-color: #ecfdf5;
  border: 1px solid #10b981;
}

.result--warning {
  background-color: #fffbeb;
  border: 1px solid #f59e0b;
}

.result-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #1f2937;
}

.result-icon {
  font-size: 16px;
}

.result-errors {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.result-errors p {
  font-size: 13px;
  color: #6b7280;
  margin: 0 0 8px 0;
}

.result-errors ul {
  margin: 0;
  padding-left: 20px;
}

.result-errors li {
  font-size: 12px;
  color: #ef4444;
  margin-bottom: 4px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 20px;
  border-top: 1px solid #e5e7eb;
}

.btn-cancel {
  padding: 10px 20px;
  background-color: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background-color: #f3f4f6;
}

.btn-import {
  padding: 10px 20px;
  background-color: #3b82f6;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-import:hover:not(:disabled) {
  background-color: #2563eb;
}

.btn-import:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
