<template>
  <div class="settings-overlay" @click.self="onClose">
    <div class="settings-modal">
      <!-- Header -->
      <div class="settings-header">
        <div class="settings-header__text">
          <h2>Configurações do Kanban</h2>
          <p>Gerencie seus pipelines, estágios e campos</p>
        </div>
        <button class="settings-close" @click="onClose">✕</button>
      </div>

      <!-- Tabs -->
      <div class="settings-tabs">
        <button
          class="settings-tab"
          :class="{ 'settings-tab--active': activeTab === 'pipelines' }"
          @click="activeTab = 'pipelines'"
        >
          Pipelines & Estágios
        </button>
        <button
          class="settings-tab"
          :class="{ 'settings-tab--active': activeTab === 'fields' }"
          @click="activeTab = 'fields'"
        >
          Campos Personalizados
        </button>
        <button
          v-if="isAdmin"
          class="settings-tab"
          :class="{ 'settings-tab--active': activeTab === 'permissions' }"
          @click="activeTab = 'permissions'"
        >
          Permissões
        </button>
      </div>

      <!-- Content -->
      <div class="settings-body">
        <!-- Tab: Pipelines & Stages -->
        <template v-if="activeTab === 'pipelines'">
          <!-- Pipelines Section -->
          <div class="settings-section">
            <div class="settings-section__header">
              <h3>Pipelines</h3>
              <button class="btn-primary-sm" @click="openAddPipeline">
                + Novo Pipeline
              </button>
            </div>

            <div v-if="pipelines.length === 0" class="settings-empty">
              Nenhum pipeline criado ainda.
            </div>

            <div v-else class="settings-list">
              <div
                v-for="p in pipelines"
                :key="p.id"
                class="settings-item"
                :class="{ 'settings-item--selected': p.id === pipeline?.id }"
              >
                <div class="settings-item__info">
                  <strong>{{ p.name }}</strong>
                </div>
                <div class="settings-item__actions">
                  <button class="btn-icon" @click="editPipeline(p)">✏️</button>
                  <button class="btn-icon" @click="confirmDeletePipeline(p)">🗑️</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Stages Section -->
          <div v-if="pipeline" class="settings-section">
            <div class="settings-section__header">
              <h3>Estágios de "{{ pipeline.name }}"</h3>
              <button class="btn-primary-sm" @click="openAddStage">
                + Novo Estágio
              </button>
            </div>

            <div v-if="stages.length === 0" class="settings-empty">
              Nenhum estágio criado ainda.
            </div>

            <div v-else class="settings-list">
              <div v-for="stage in stages" :key="stage.id" class="settings-item">
                <div class="settings-item__color" :style="{ backgroundColor: stage.color }"></div>
                <div class="settings-item__info">
                  <strong>{{ stage.name }}</strong>
                  <span>Posição {{ stage.position }}</span>
                </div>
                <div class="settings-item__actions">
                  <button class="btn-icon" @click="editStage(stage)">✏️</button>
                  <button class="btn-icon" @click="confirmDeleteStage(stage)">🗑️</button>
                </div>
              </div>
            </div>
          </div>
        </template>

        <!-- Tab: Custom Fields -->
        <template v-if="activeTab === 'fields'">
          <div v-if="!pipeline" class="settings-empty">
            Selecione um pipeline para gerenciar os campos personalizados.
          </div>
          <KanbanCustomFieldsManager
            v-else
            :account-id="accountId"
            :pipeline-id="pipeline.id"
          />
        </template>

        <!-- Tab: Permissions -->
        <template v-if="activeTab === 'permissions'">
          <CrmPermissionsManager :account-id="accountId" />
        </template>
      </div>

      <!-- Footer -->
      <div class="settings-footer">
        <button class="btn-secondary" @click="onClose">Fechar</button>
      </div>
    </div>

    <!-- Pipeline Form -->
    <div v-if="showPipelineForm" class="settings-overlay" @click.self="closePipelineForm">
      <div class="form-modal">
        <div class="form-modal__header">
          <h3>{{ editingPipeline ? 'Editar Pipeline' : 'Novo Pipeline' }}</h3>
          <button class="settings-close" @click="closePipelineForm">✕</button>
        </div>
        <form class="form-modal__body" @submit.prevent="savePipeline">
          <div class="form-field">
            <label>Nome</label>
            <input
              v-model="pipelineForm.name"
              type="text"
              placeholder="Ex: Vendas Solar"
              required
            />
          </div>
          <input type="hidden" v-model="pipelineForm.pipeline_type" />
          <div class="form-modal__footer">
            <button type="button" class="btn-secondary" @click="closePipelineForm">Cancelar</button>
            <button type="submit" class="btn-primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Stage Form -->
    <div v-if="showStageForm" class="settings-overlay" @click.self="closeStageForm">
      <div class="form-modal">
        <div class="form-modal__header">
          <h3>{{ editingStage ? 'Editar Estágio' : 'Novo Estágio' }}</h3>
          <button class="settings-close" @click="closeStageForm">✕</button>
        </div>
        <form class="form-modal__body" @submit.prevent="saveStage">
          <div class="form-field">
            <label>Nome</label>
            <input
              v-model="stageForm.name"
              type="text"
              placeholder="Ex: Novo Lead"
              required
            />
          </div>
          <div class="form-field">
            <label>Cor</label>
            <div class="color-picker">
              <input v-model="stageForm.color" type="color" />
              <span>{{ stageForm.color }}</span>
            </div>
          </div>
          <div class="form-field">
            <label>Posição</label>
            <input v-model.number="stageForm.position" type="number" min="0" />
          </div>
          <div class="form-modal__footer">
            <button type="button" class="btn-secondary" @click="closeStageForm">Cancelar</button>
            <button type="submit" class="btn-primary" :disabled="isSaving">
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import KanbanAPI from 'dashboard/api/kanban';
import KanbanCustomFieldsManager from 'dashboard/components/kanban/KanbanCustomFieldsManager.vue';
import CrmPermissionsManager from 'dashboard/components/kanban/CrmPermissionsManager.vue';

export default {
  name: 'KanbanSettingsModal',
  components: {
    KanbanCustomFieldsManager,
    CrmPermissionsManager,
  },
  props: {
    pipeline: { type: Object, default: null },
    pipelines: { type: Array, default: () => [] },
  },
  emits: ['close', 'saved'],
  data() {
    return {
      activeTab: 'pipelines',
      showPipelineForm: false,
      showStageForm: false,
      editingPipeline: null,
      editingStage: null,
      isSaving: false,
      pipelineForm: { name: '', pipeline_type: 'conversations' },
      stageForm: { name: '', color: '#6366F1', position: 0 },
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    stages() {
      return this.pipeline?.kanban_stages || [];
    },
    accountId() {
      return this.$route.params.accountId;
    },
    isAdmin() {
      return this.currentUser?.role === 'administrator';
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    openAddPipeline() {
      this.editingPipeline = null;
      this.pipelineForm = { name: '', pipeline_type: 'conversations' };
      this.showPipelineForm = true;
    },
    editPipeline(p) {
      this.editingPipeline = p;
      this.pipelineForm = { name: p.name, pipeline_type: 'conversations' };
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
        alert('Erro ao salvar pipeline: ' + (error.response?.data?.errors?.join(', ') || error.message));
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeletePipeline(p) {
      if (confirm(`Excluir o pipeline "${p.name}"?`)) {
        try {
          await KanbanAPI.deletePipeline(this.accountId, p.id);
          this.$emit('saved');
        } catch (error) {
          alert('Erro ao excluir pipeline');
        }
      }
    },
    openAddStage() {
      this.editingStage = null;
      this.stageForm = { name: '', color: '#6366F1', position: this.stages.length };
      this.showStageForm = true;
    },
    editStage(stage) {
      this.editingStage = stage;
      this.stageForm = { name: stage.name, color: stage.color, position: stage.position };
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
        alert('Erro ao salvar estágio: ' + (error.response?.data?.errors?.join(', ') || error.message));
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeleteStage(stage) {
      if (confirm(`Excluir o estágio "${stage.name}"?`)) {
        try {
          await KanbanAPI.deleteStage(this.accountId, this.pipeline.id, stage.id);
          this.$emit('saved');
        } catch (error) {
          alert('Erro ao excluir estágio');
        }
      }
    },
  },
};
</script>

<style scoped>
.settings-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
}

.settings-modal {
  background-color: rgb(var(--slate-2));
  border-radius: 12px;
  width: 800px;
  max-width: 90vw;
  height: 680px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
  border: 1px solid rgb(var(--slate-4));
}

.settings-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid rgb(var(--slate-4));
  flex-shrink: 0;
}

.settings-header__text h2 {
  font-size: 18px;
  font-weight: 600;
  color: rgb(var(--slate-12));
  margin: 0 0 4px 0;
}

.settings-header__text p {
  font-size: 13px;
  color: rgb(var(--slate-10));
  margin: 0;
}

.settings-close {
  background: none;
  border: none;
  font-size: 20px;
  color: rgb(var(--slate-10));
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
}

.settings-close:hover {
  background-color: rgb(var(--slate-4));
  color: rgb(var(--slate-12));
}

.settings-tabs {
  display: flex;
  gap: 0;
  padding: 0 24px;
  border-bottom: 1px solid rgb(var(--slate-4));
  flex-shrink: 0;
}

.settings-tab {
  padding: 12px 20px;
  background: none;
  border: none;
  color: rgb(var(--slate-10));
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  transition: all 0.2s;
}

.settings-tab:hover {
  color: rgb(var(--slate-12));
}

.settings-tab--active {
  color: rgb(var(--blue-9));
  border-bottom-color: rgb(var(--blue-9));
}

.settings-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  min-height: 0;
}

.settings-section {
  margin-bottom: 28px;
}

.settings-section:last-child {
  margin-bottom: 0;
}

.settings-section__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.settings-section__header h3 {
  font-size: 14px;
  font-weight: 600;
  color: rgb(var(--slate-12));
  margin: 0;
}

.settings-empty {
  padding: 20px;
  text-align: center;
  background-color: rgb(var(--slate-1));
  border-radius: 8px;
  color: rgb(var(--slate-10));
  font-size: 14px;
}

.settings-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.settings-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  background-color: rgb(var(--slate-1));
  border-radius: 8px;
  border: 1px solid rgb(var(--slate-4));
}

.settings-item--selected {
  border-color: rgb(var(--blue-9));
  background-color: rgb(var(--blue-3));
}

.settings-item__color {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  margin-right: 12px;
  flex-shrink: 0;
  border: 2px solid rgb(var(--slate-6));
}

.settings-item__info {
  flex: 1;
  min-width: 0;
}

.settings-item__info strong {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: rgb(var(--slate-12));
}

.settings-item__info span {
  display: block;
  font-size: 12px;
  color: rgb(var(--slate-10));
  margin-top: 2px;
}

.settings-item__actions {
  display: flex;
  gap: 4px;
}

.settings-footer {
  display: flex;
  justify-content: flex-end;
  padding: 16px 24px;
  border-top: 1px solid rgb(var(--slate-4));
  flex-shrink: 0;
}

.btn-primary-sm {
  padding: 6px 12px;
  background-color: rgb(var(--blue-9));
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary-sm:hover {
  background-color: rgb(var(--blue-10));
}

.btn-primary {
  padding: 10px 20px;
  background-color: rgb(var(--blue-9));
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary:hover {
  background-color: rgb(var(--blue-10));
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  padding: 10px 20px;
  background-color: rgb(var(--slate-4));
  color: rgb(var(--slate-12));
  border: 1px solid rgb(var(--slate-6));
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.btn-secondary:hover {
  background-color: rgb(var(--slate-5));
}

.btn-icon {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-icon:hover {
  background-color: rgb(var(--slate-4));
}

.form-modal {
  background-color: rgb(var(--slate-2));
  border-radius: 12px;
  width: 400px;
  max-width: 90vw;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
  border: 1px solid rgb(var(--slate-4));
}

.form-modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid rgb(var(--slate-4));
}

.form-modal__header h3 {
  font-size: 16px;
  font-weight: 600;
  color: rgb(var(--slate-12));
  margin: 0;
}

.form-modal__body {
  padding: 20px;
}

.form-field {
  margin-bottom: 16px;
}

.form-field:last-of-type {
  margin-bottom: 0;
}

.form-field label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: rgb(var(--slate-11));
  margin-bottom: 6px;
}

.form-field input[type="text"],
.form-field input[type="number"],
.form-field select {
  width: 100%;
  padding: 10px 12px;
  background-color: rgb(var(--slate-1));
  border: 1px solid rgb(var(--slate-4));
  border-radius: 6px;
  font-size: 14px;
  color: rgb(var(--slate-12));
  box-sizing: border-box;
}

.form-field input:focus,
.form-field select:focus {
  outline: none;
  border-color: rgb(var(--blue-9));
}

.form-field input::placeholder {
  color: rgb(var(--slate-9));
}

.form-field small {
  display: block;
  font-size: 12px;
  color: rgb(var(--slate-9));
  margin-top: 6px;
}

.color-picker {
  display: flex;
  align-items: center;
  gap: 12px;
}

.color-picker input[type="color"] {
  width: 48px;
  height: 40px;
  padding: 2px;
  background-color: rgb(var(--slate-1));
  border: 1px solid rgb(var(--slate-4));
  border-radius: 6px;
  cursor: pointer;
}

.color-picker span {
  font-size: 14px;
  color: rgb(var(--slate-10));
  font-family: monospace;
}

.form-modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid rgb(var(--slate-4));
}
</style>
