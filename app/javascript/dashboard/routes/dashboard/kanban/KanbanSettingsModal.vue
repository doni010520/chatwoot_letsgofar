<template>
  <div class="modal-overlay" @click.self="onClose">
    <div class="kanban-settings">
      <div class="kanban-settings__header">
        <h2>Configurações do Kanban</h2>
        <button class="kanban-settings__close" @click="onClose">✕</button>
      </div>

      <div class="kanban-settings__content">
        <!-- Criar novo pipeline -->
        <div class="kanban-settings__section">
          <div class="kanban-settings__section-header">
            <h3>Pipelines</h3>
            <button class="btn btn--primary btn--small" @click="showAddPipeline = true">
              + Novo Pipeline
            </button>
          </div>
          
          <div class="kanban-settings__pipelines">
            <div
              v-for="p in pipelines"
              :key="p.id"
              class="kanban-settings__pipeline"
              :class="{ 'kanban-settings__pipeline--active': p.id === pipeline?.id }"
            >
              <span class="kanban-settings__pipeline-name">{{ p.name }}</span>
              <span class="kanban-settings__pipeline-type">{{ getPipelineTypeLabel(p.pipeline_type) }}</span>
              <button class="btn btn--icon" @click="editPipeline(p)">✏️</button>
              <button class="btn btn--icon btn--danger" @click="confirmDeletePipeline(p)">🗑️</button>
            </div>
          </div>
        </div>

        <!-- Estágios do Pipeline selecionado -->
        <div v-if="pipeline" class="kanban-settings__section">
          <div class="kanban-settings__section-header">
            <h3>Estágios de "{{ pipeline.name }}"</h3>
            <button class="btn btn--primary btn--small" @click="openAddStage">
              + Novo Estágio
            </button>
          </div>

          <div v-if="stages.length === 0" class="kanban-settings__empty">
            Nenhum estágio criado ainda.
          </div>

          <div v-else class="kanban-settings__stages">
            <div
              v-for="stage in stages"
              :key="stage.id"
              class="kanban-settings__stage"
            >
              <span
                class="kanban-settings__stage-color"
                :style="{ backgroundColor: stage.color }"
              ></span>
              <span class="kanban-settings__stage-name">{{ stage.name }}</span>
              <span class="kanban-settings__stage-position">#{{ stage.position }}</span>
              <button class="btn btn--icon" @click="editStage(stage)">✏️</button>
              <button class="btn btn--icon btn--danger" @click="confirmDeleteStage(stage)">🗑️</button>
            </div>
          </div>
        </div>
      </div>

      <div class="kanban-settings__footer">
        <button class="btn" @click="onClose">Fechar</button>
      </div>
    </div>

    <!-- Modal: Criar/Editar Pipeline -->
    <div v-if="showAddPipeline || editingPipeline" class="modal-overlay" @click.self="closePipelineModal">
      <div class="stage-form">
        <div class="stage-form__header">
          <h3>{{ editingPipeline ? 'Editar Pipeline' : 'Novo Pipeline' }}</h3>
          <button class="kanban-settings__close" @click="closePipelineModal">✕</button>
        </div>
        <form @submit.prevent="savePipeline">
          <div class="form-group">
            <label>Nome</label>
            <input
              v-model="pipelineForm.name"
              type="text"
              placeholder="Nome do pipeline"
              required
            />
          </div>
          <div class="form-group">
            <label>Tipo</label>
            <select v-model="pipelineForm.pipeline_type">
              <option value="conversations">Conversas</option>
              <option value="contacts">Contatos</option>
            </select>
          </div>
          <div class="stage-form__actions">
            <button type="submit" class="btn btn--primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
            <button type="button" class="btn" @click="closePipelineModal">Cancelar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal: Criar/Editar Stage -->
    <div v-if="showAddStage || editingStage" class="modal-overlay" @click.self="closeStageModal">
      <div class="stage-form">
        <div class="stage-form__header">
          <h3>{{ editingStage ? 'Editar Estágio' : 'Novo Estágio' }}</h3>
          <button class="kanban-settings__close" @click="closeStageModal">✕</button>
        </div>
        <form @submit.prevent="saveStage">
          <div class="form-group">
            <label>Nome</label>
            <input
              v-model="stageForm.name"
              type="text"
              placeholder="Nome do estágio"
              required
            />
          </div>
          <div class="form-group">
            <label>Cor</label>
            <div class="color-picker">
              <input
                v-model="stageForm.color"
                type="color"
              />
              <span>{{ stageForm.color }}</span>
            </div>
          </div>
          <div class="form-group">
            <label>Posição</label>
            <input
              v-model.number="stageForm.position"
              type="number"
              min="0"
            />
          </div>
          <div class="stage-form__actions">
            <button type="submit" class="btn btn--primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
            <button type="button" class="btn" @click="closeStageModal">Cancelar</button>
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
      showAddPipeline: false,
      editingPipeline: null,
      showAddStage: false,
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
    editPipeline(p) {
      this.editingPipeline = p;
      this.pipelineForm = {
        name: p.name,
        pipeline_type: p.pipeline_type,
      };
    },
    closePipelineModal() {
      this.showAddPipeline = false;
      this.editingPipeline = null;
      this.pipelineForm = {
        name: '',
        pipeline_type: 'conversations',
      };
    },
    async savePipeline() {
      this.isSaving = true;
      try {
        if (this.editingPipeline) {
          await KanbanAPI.updatePipeline(
            this.accountId,
            this.editingPipeline.id,
            this.pipelineForm
          );
        } else {
          await KanbanAPI.createPipeline(this.accountId, this.pipelineForm);
        }
        this.closePipelineModal();
        this.$emit('saved');
      } catch (error) {
        console.error('Error saving pipeline:', error);
        alert('Erro ao salvar pipeline');
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeletePipeline(p) {
      if (confirm(`Tem certeza que deseja excluir o pipeline "${p.name}"?`)) {
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
      this.stageForm.position = this.stages.length;
      this.showAddStage = true;
    },
    editStage(stage) {
      this.editingStage = stage;
      this.stageForm = {
        name: stage.name,
        color: stage.color,
        position: stage.position,
      };
    },
    closeStageModal() {
      this.showAddStage = false;
      this.editingStage = null;
      this.stageForm = {
        name: '',
        color: '#6366F1',
        position: 0,
      };
    },
    async saveStage() {
      this.isSaving = true;
      try {
        if (this.editingStage) {
          await KanbanAPI.updateStage(
            this.accountId,
            this.pipeline.id,
            this.editingStage.id,
            this.stageForm
          );
        } else {
          await KanbanAPI.createStage(
            this.accountId,
            this.pipeline.id,
            this.stageForm
          );
        }
        this.closeStageModal();
        this.$emit('saved');
      } catch (error) {
        console.error('Error saving stage:', error);
        alert('Erro ao salvar estágio');
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeleteStage(stage) {
      if (confirm(`Tem certeza que deseja excluir o estágio "${stage.name}"?`)) {
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
  z-index: 9999;
}

.kanban-settings {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  width: 600px;
  max-width: 90vw;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-normal);
    border-bottom: 1px solid var(--s-100);

    h2 {
      margin: 0;
      font-size: var(--font-size-large);
      color: var(--s-800);
    }
  }

  &__close {
    background: none;
    border: none;
    font-size: var(--font-size-large);
    cursor: pointer;
    color: var(--s-500);
    padding: var(--space-small);

    &:hover {
      color: var(--s-800);
    }
  }

  &__content {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-normal);
  }

  &__section {
    margin-bottom: var(--space-large);

    h3 {
      margin: 0;
      font-size: var(--font-size-default);
      color: var(--s-800);
    }
  }

  &__section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: var(--space-small);
  }

  &__pipelines,
  &__stages {
    display: flex;
    flex-direction: column;
    gap: var(--space-small);
  }

  &__pipeline,
  &__stage {
    display: flex;
    align-items: center;
    gap: var(--space-small);
    padding: var(--space-small);
    background-color: var(--s-50);
    border-radius: var(--border-radius-normal);
  }

  &__pipeline--active {
    background-color: var(--w-50);
    border: 1px solid var(--w-200);
  }

  &__pipeline-name,
  &__stage-name {
    flex: 1;
    font-weight: var(--font-weight-medium);
    color: var(--s-800);
  }

  &__pipeline-type {
    font-size: var(--font-size-small);
    color: var(--s-500);
  }

  &__stage-color {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  &__stage-position {
    font-size: var(--font-size-small);
    color: var(--s-500);
  }

  &__empty {
    padding: var(--space-normal);
    text-align: center;
    color: var(--s-500);
  }

  &__footer {
    display: flex;
    justify-content: flex-end;
    padding: var(--space-normal);
    border-top: 1px solid var(--s-100);
  }
}

.stage-form {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  width: 400px;
  max-width: 90vw;
  padding: var(--space-normal);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: var(--space-normal);

    h3 {
      margin: 0;
      font-size: var(--font-size-medium);
      color: var(--s-800);
    }
  }

  &__actions {
    display: flex;
    gap: var(--space-small);
    justify-content: flex-end;
    margin-top: var(--space-normal);
  }
}

.form-group {
  margin-bottom: var(--space-normal);

  label {
    display: block;
    margin-bottom: var(--space-micro);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    color: var(--s-700);
  }

  input,
  select {
    width: 100%;
    padding: var(--space-small);
    border: 1px solid var(--s-200);
    border-radius: var(--border-radius-normal);
    font-size: var(--font-size-default);
    color: var(--s-800);

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }
  }
}

.color-picker {
  display: flex;
  align-items: center;
  gap: var(--space-small);

  input[type="color"] {
    width: 40px;
    height: 40px;
    padding: 0;
    border: 1px solid var(--s-200);
    border-radius: var(--border-radius-normal);
    cursor: pointer;
  }

  span {
    font-size: var(--font-size-small);
    color: var(--s-600);
  }
}

.btn {
  padding: var(--space-small) var(--space-normal);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--s-200);
  background-color: var(--white);
  color: var(--s-800);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background-color: var(--s-50);
  }

  &--primary {
    background-color: var(--w-500);
    border-color: var(--w-500);
    color: var(--white);

    &:hover {
      background-color: var(--w-600);
    }

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
  }

  &--small {
    padding: var(--space-micro) var(--space-small);
    font-size: var(--font-size-mini);
  }

  &--icon {
    padding: var(--space-micro);
    background: transparent;
    border: none;

    &:hover {
      background-color: var(--s-100);
    }
  }

  &--danger {
    &:hover {
      background-color: var(--r-50);
    }
  }
}
</style>
