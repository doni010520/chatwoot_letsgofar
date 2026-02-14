<template>
  <div class="modal-backdrop" @click.self="onClose">
    <div class="modal-container">
      <!-- Header -->
      <div class="modal-header">
        <div>
          <h2>Configurações do Kanban</h2>
          <p>Gerencie seus pipelines e estágios</p>
        </div>
        <button class="close-btn" @click="onClose">✕</button>
      </div>

      <!-- Content -->
      <div class="modal-content">
        <!-- Pipelines Section -->
        <div class="section">
          <div class="section-header">
            <h3>Pipelines</h3>
            <button class="btn btn-primary btn-sm" @click="openAddPipeline">
              + Novo Pipeline
            </button>
          </div>

          <div v-if="pipelines.length === 0" class="empty-state">
            <p>Nenhum pipeline criado ainda.</p>
          </div>

          <div v-else class="pipeline-list">
            <div
              v-for="p in pipelines"
              :key="p.id"
              class="pipeline-item"
              :class="{ 'pipeline-item--active': p.id === pipeline?.id }"
            >
              <div class="pipeline-info">
                <span class="pipeline-name">{{ p.name }}</span>
                <span class="pipeline-type">{{ getPipelineTypeLabel(p.pipeline_type) }}</span>
              </div>
              <div class="pipeline-actions">
                <button class="btn-icon" @click="editPipeline(p)" title="Editar">✏️</button>
                <button class="btn-icon btn-icon--danger" @click="confirmDeletePipeline(p)" title="Excluir">🗑️</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Stages Section -->
        <div v-if="pipeline" class="section">
          <div class="section-header">
            <h3>Estágios de "{{ pipeline.name }}"</h3>
            <button class="btn btn-primary btn-sm" @click="openAddStage">
              + Novo Estágio
            </button>
          </div>

          <div v-if="stages.length === 0" class="empty-state">
            <p>Nenhum estágio criado ainda.</p>
          </div>

          <div v-else class="stage-list">
            <div v-for="stage in stages" :key="stage.id" class="stage-item">
              <div class="stage-color" :style="{ backgroundColor: stage.color }"></div>
              <div class="stage-info">
                <span class="stage-name">{{ stage.name }}</span>
                <span class="stage-position">Posição {{ stage.position }}</span>
              </div>
              <div class="stage-actions">
                <button class="btn-icon" @click="editStage(stage)" title="Editar">✏️</button>
                <button class="btn-icon btn-icon--danger" @click="confirmDeleteStage(stage)" title="Excluir">🗑️</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="onClose">Fechar</button>
      </div>
    </div>

    <!-- Pipeline Form Modal -->
    <div v-if="showPipelineForm" class="modal-backdrop" @click.self="closePipelineForm">
      <div class="form-modal">
        <div class="form-header">
          <h3>{{ editingPipeline ? 'Editar Pipeline' : 'Novo Pipeline' }}</h3>
          <button class="close-btn" @click="closePipelineForm">✕</button>
        </div>
        <form @submit.prevent="savePipeline">
          <div class="form-group">
            <label for="pipeline-name">Nome</label>
            <input
              id="pipeline-name"
              v-model="pipelineForm.name"
              type="text"
              placeholder="Ex: Vendas Solar"
              required
            />
          </div>
          <div class="form-group">
            <label for="pipeline-type">Tipo</label>
            <select id="pipeline-type" v-model="pipelineForm.pipeline_type">
              <option value="conversations">Conversas</option>
              <option value="contacts">Contatos</option>
            </select>
            <span class="form-hint">
              Conversas: organiza chats pelo funil. Contatos: organiza contatos.
            </span>
          </div>
          <div class="form-actions">
            <button type="button" class="btn btn-secondary" @click="closePipelineForm">
              Cancelar
            </button>
            <button type="submit" class="btn btn-primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Stage Form Modal -->
    <div v-if="showStageForm" class="modal-backdrop" @click.self="closeStageForm">
      <div class="form-modal">
        <div class="form-header">
          <h3>{{ editingStage ? 'Editar Estágio' : 'Novo Estágio' }}</h3>
          <button class="close-btn" @click="closeStageForm">✕</button>
        </div>
        <form @submit.prevent="saveStage">
          <div class="form-group">
            <label for="stage-name">Nome</label>
            <input
              id="stage-name"
              v-model="stageForm.name"
              type="text"
              placeholder="Ex: Novo Lead"
              required
            />
          </div>
          <div class="form-group">
            <label for="stage-color">Cor</label>
            <div class="color-input">
              <input
                id="stage-color"
                v-model="stageForm.color"
                type="color"
              />
              <span class="color-value">{{ stageForm.color }}</span>
            </div>
          </div>
          <div class="form-group">
            <label for="stage-position">Posição</label>
            <input
              id="stage-position"
              v-model.number="stageForm.position"
              type="number"
              min="0"
            />
          </div>
          <div class="form-actions">
            <button type="button" class="btn btn-secondary" @click="closeStageForm">
              Cancelar
            </button>
            <button type="submit" class="btn btn-primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanSettingsModal',
  props: {
    pipeline: {
      type: Object,
      default: null,
    },
    pipelines: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['close', 'saved'],
  data() {
    return {
      showPipelineForm: false,
      showStageForm: false,
      editingPipeline: null,
      editingStage: null,
      isSaving: false,
      pipelineForm: {
        name: '',
        pipeline_type: 'conversations',
      },
      stageForm: {
        name: '',
        color: '#6366F1',
        position: 0,
      },
    };
  },
  computed: {
    stages() {
      return this.pipeline?.kanban_stages || [];
    },
    accountId() {
      return this.$route.params.accountId;
    },
  },
  methods: {
    getPipelineTypeLabel(type) {
      const types = {
        conversations: 'Conversas',
        contacts: 'Contatos',
      };
      return types[type] || type;
    },
    onClose() {
      this.$emit('close');
    },

    // Pipeline methods
    openAddPipeline() {
      this.editingPipeline = null;
      this.pipelineForm = { name: '', pipeline_type: 'conversations' };
      this.showPipelineForm = true;
    },
    editPipeline(p) {
      this.editingPipeline = p;
      this.pipelineForm = {
        name: p.name,
        pipeline_type: p.pipeline_type,
      };
      this.showPipelineForm = true;
    },
    closePipelineForm() {
      this.showPipelineForm = false;
      this.editingPipeline = null;
    },
    async savePipeline() {
      this.isSaving = true;
      try {
        if (this.editingPipeline) {
          await KanbanAPI.updatePipeline(this.accountId, this.editingPipeline.id, this.pipelineForm);
        } else {
          await KanbanAPI.createPipeline(this.accountId, this.pipelineForm);
        }
        this.closePipelineForm();
        this.$emit('saved');
      } catch (error) {
        console.error('Error saving pipeline:', error);
        alert('Erro ao salvar pipeline: ' + (error.response?.data?.errors?.join(', ') || error.message));
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeletePipeline(p) {
      if (confirm(`Excluir o pipeline "${p.name}"? Esta ação não pode ser desfeita.`)) {
        try {
          await KanbanAPI.deletePipeline(this.accountId, p.id);
          this.$emit('saved');
        } catch (error) {
          console.error('Error deleting pipeline:', error);
          alert('Erro ao excluir pipeline');
        }
      }
    },

    // Stage methods
    openAddStage() {
      this.editingStage = null;
      this.stageForm = { name: '', color: '#6366F1', position: this.stages.length };
      this.showStageForm = true;
    },
    editStage(stage) {
      this.editingStage = stage;
      this.stageForm = {
        name: stage.name,
        color: stage.color,
        position: stage.position,
      };
      this.showStageForm = true;
    },
    closeStageForm() {
      this.showStageForm = false;
      this.editingStage = null;
    },
    async saveStage() {
      this.isSaving = true;
      try {
        if (this.editingStage) {
          await KanbanAPI.updateStage(this.accountId, this.pipeline.id, this.editingStage.id, this.stageForm);
        } else {
          await KanbanAPI.createStage(this.accountId, this.pipeline.id, this.stageForm);
        }
        this.closeStageForm();
        this.$emit('saved');
      } catch (error) {
        console.error('Error saving stage:', error);
        alert('Erro ao salvar estágio: ' + (error.response?.data?.errors?.join(', ') || error.message));
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeleteStage(stage) {
      if (confirm(`Excluir o estágio "${stage.name}"? Esta ação não pode ser desfeita.`)) {
        try {
          await KanbanAPI.deleteStage(this.accountId, this.pipeline.id, stage.id);
          this.$emit('saved');
        } catch (error) {
          console.error('Error deleting stage:', error);
          alert('Erro ao excluir estágio');
        }
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.modal-container {
  background-color: var(--white);
  border-radius: 12px;
  width: 600px;
  max-width: 90vw;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 24px;
  border-bottom: 1px solid var(--s-100);

  h2 {
    font-size: 18px;
    font-weight: 600;
    color: var(--s-900);
    margin: 0;
  }

  p {
    font-size: 13px;
    color: var(--s-500);
    margin: 4px 0 0 0;
  }
}

.close-btn {
  background: none;
  border: none;
  font-size: 20px;
  color: var(--s-400);
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: all 0.2s;

  &:hover {
    background-color: var(--s-100);
    color: var(--s-600);
  }
}

.modal-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 16px 24px;
  border-top: 1px solid var(--s-100);
}

.section {
  margin-bottom: 32px;

  &:last-child {
    margin-bottom: 0;
  }
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;

  h3 {
    font-size: 15px;
    font-weight: 600;
    color: var(--s-800);
    margin: 0;
  }
}

.empty-state {
  padding: 24px;
  text-align: center;
  background-color: var(--s-50);
  border-radius: 8px;

  p {
    color: var(--s-500);
    margin: 0;
    font-size: 14px;
  }
}

.pipeline-list,
.stage-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.pipeline-item,
.stage-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  background-color: var(--s-50);
  border-radius: 8px;
  border: 1px solid transparent;
  transition: all 0.2s;

  &:hover {
    background-color: var(--s-75);
  }
}

.pipeline-item--active {
  background-color: var(--w-50);
  border-color: var(--w-200);
}

.pipeline-info,
.stage-info {
  flex: 1;
  min-width: 0;
}

.pipeline-name,
.stage-name {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: var(--s-800);
}

.pipeline-type,
.stage-position {
  display: block;
  font-size: 12px;
  color: var(--s-500);
  margin-top: 2px;
}

.pipeline-actions,
.stage-actions {
  display: flex;
  gap: 4px;
}

.stage-color {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  margin-right: 12px;
  flex-shrink: 0;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 10px 16px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid transparent;

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
}

.btn-primary {
  background-color: var(--w-500);
  color: var(--white);
  border-color: var(--w-500);

  &:hover:not(:disabled) {
    background-color: var(--w-600);
  }
}

.btn-secondary {
  background-color: var(--white);
  color: var(--s-700);
  border-color: var(--s-200);

  &:hover:not(:disabled) {
    background-color: var(--s-50);
  }
}

.btn-sm {
  padding: 6px 12px;
  font-size: 13px;
}

.btn-icon {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.2s;

  &:hover {
    background-color: var(--s-200);
  }

  &--danger:hover {
    background-color: var(--r-100);
  }
}

/* Form Modal */
.form-modal {
  background-color: var(--white);
  border-radius: 12px;
  width: 420px;
  max-width: 90vw;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.form-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--s-100);

  h3 {
    font-size: 16px;
    font-weight: 600;
    color: var(--s-900);
    margin: 0;
  }
}

form {
  padding: 24px;
}

.form-group {
  margin-bottom: 20px;

  &:last-of-type {
    margin-bottom: 0;
  }

  label {
    display: block;
    font-size: 13px;
    font-weight: 500;
    color: var(--s-700);
    margin-bottom: 8px;
  }

  input[type="text"],
  input[type="number"],
  select {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    font-size: 14px;
    color: var(--s-800);
    background-color: var(--white);
    transition: border-color 0.2s;

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }

    &::placeholder {
      color: var(--s-400);
    }
  }
}

.form-hint {
  display: block;
  font-size: 12px;
  color: var(--s-500);
  margin-top: 6px;
}

.color-input {
  display: flex;
  align-items: center;
  gap: 12px;

  input[type="color"] {
    width: 48px;
    height: 48px;
    padding: 4px;
    border: 1px solid var(--s-200);
    border-radius: 6px;
    cursor: pointer;
    background: none;
  }

  .color-value {
    font-size: 14px;
    color: var(--s-600);
    font-family: monospace;
  }
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--s-100);
}
</style>
