<template>
  <woot-modal
    :show="true"
    :on-close="onClose"
  >
    <div class="kanban-settings">
      <woot-modal-header
        header-title="Configurações do Kanban"
        header-content="Gerencie pipelines e estágios"
      />

      <div class="kanban-settings__content">
        <!-- Pipeline atual -->
        <div class="kanban-settings__section">
          <h3>Pipeline: {{ pipeline?.name }}</h3>
          <p class="kanban-settings__description">
            Tipo: {{ pipelineTypeLabel }}
          </p>
        </div>

        <!-- Lista de Estágios -->
        <div class="kanban-settings__section">
          <div class="kanban-settings__section-header">
            <h4>Estágios</h4>
            <woot-button
              size="small"
              icon="add"
              @click="showAddStage = true"
            >
              Novo Estágio
            </woot-button>
          </div>

          <div class="kanban-settings__stages">
            <div
              v-for="stage in stages"
              :key="stage.id"
              class="kanban-settings__stage"
            >
              <span
                class="kanban-settings__stage-color"
                :style="{ backgroundColor: stage.color }"
              />
              <span class="kanban-settings__stage-name">{{ stage.name }}</span>
              <span class="kanban-settings__stage-position">#{{ stage.position }}</span>
              <woot-button
                size="tiny"
                variant="smooth"
                color-scheme="secondary"
                icon="edit"
                @click="editStage(stage)"
              />
              <woot-button
                size="tiny"
                variant="smooth"
                color-scheme="alert"
                icon="delete"
                @click="confirmDeleteStage(stage)"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Add/Edit Stage Modal -->
      <woot-modal
        :show="showAddStage || editingStage !== null"
        :on-close="closeStageModal"
      >
        <div class="stage-form">
          <woot-modal-header
            :header-title="editingStage ? 'Editar Estágio' : 'Novo Estágio'"
          />
          <form @submit.prevent="saveStage">
            <woot-input
              v-model="stageForm.name"
              label="Nome"
              placeholder="Nome do estágio"
              required
            />
            <woot-input
              v-model="stageForm.color"
              label="Cor"
              type="color"
            />
            <woot-input
              v-model.number="stageForm.position"
              label="Posição"
              type="number"
              min="0"
            />
            <div class="stage-form__actions">
              <woot-button
                type="submit"
                :is-loading="isSaving"
              >
                Salvar
              </woot-button>
              <woot-button
                variant="smooth"
                color-scheme="secondary"
                @click="closeStageModal"
              >
                Cancelar
              </woot-button>
            </div>
          </form>
        </div>
      </woot-modal>

      <div class="kanban-settings__footer">
        <woot-button
          variant="smooth"
          color-scheme="secondary"
          @click="onClose"
        >
          Fechar
        </woot-button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapActions } from 'vuex';

export default {
  name: 'KanbanSettingsModal',
  props: {
    pipeline: {
      type: Object,
      default: null,
    },
  },
  emits: ['close', 'saved'],
  data() {
    return {
      showAddStage: false,
      editingStage: null,
      isSaving: false,
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
    pipelineTypeLabel() {
      const types = {
        conversations: 'Conversas',
        contacts: 'Contatos',
        both: 'Ambos',
      };
      return types[this.pipeline?.pipeline_type] || '';
    },
    accountId() {
      return this.$route.params.accountId;
    },
  },
  methods: {
    ...mapActions('kanban', [
      'createStage',
      'updateStage',
      'deleteStage',
    ]),
    onClose() {
      this.$emit('close');
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
        position: this.stages.length,
      };
    },
    async saveStage() {
      this.isSaving = true;
      try {
        if (this.editingStage) {
          await this.updateStage({
            accountId: this.accountId,
            pipelineId: this.pipeline.id,
            stageId: this.editingStage.id,
            stageData: this.stageForm,
          });
        } else {
          await this.createStage({
            accountId: this.accountId,
            pipelineId: this.pipeline.id,
            stageData: this.stageForm,
          });
        }
        this.closeStageModal();
        this.$emit('saved');
      } catch (error) {
        console.error('Error saving stage:', error);
      } finally {
        this.isSaving = false;
      }
    },
    async confirmDeleteStage(stage) {
      const confirmed = await this.$confirm(
        `Tem certeza que deseja excluir o estágio "${stage.name}"?`
      );
      if (confirmed) {
        await this.deleteStage({
          accountId: this.accountId,
          pipelineId: this.pipeline.id,
          stageId: stage.id,
        });
        this.$emit('saved');
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-settings {
  @apply p-4;

  &__content {
    @apply space-y-6 my-4;
  }

  &__section {
    h3 {
      @apply text-lg font-semibold text-slate-800 dark:text-slate-100;
    }

    h4 {
      @apply text-base font-medium text-slate-700 dark:text-slate-200;
    }
  }

  &__section-header {
    @apply flex items-center justify-between mb-3;
  }

  &__description {
    @apply text-sm text-slate-500 dark:text-slate-400;
  }

  &__stages {
    @apply space-y-2;
  }

  &__stage {
    @apply flex items-center gap-3 p-3 bg-slate-50 dark:bg-slate-700 rounded-lg;
  }

  &__stage-color {
    @apply w-4 h-4 rounded-full;
  }

  &__stage-name {
    @apply flex-1 font-medium text-slate-800 dark:text-slate-100;
  }

  &__stage-position {
    @apply text-sm text-slate-500 dark:text-slate-400;
  }

  &__footer {
    @apply flex justify-end pt-4 border-t border-slate-100 dark:border-slate-700;
  }
}

.stage-form {
  @apply p-4;

  form {
    @apply space-y-4 mt-4;
  }

  &__actions {
    @apply flex gap-2 justify-end pt-4;
  }
}
</style>