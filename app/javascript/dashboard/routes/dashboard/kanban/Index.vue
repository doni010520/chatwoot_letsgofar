<template>
  <div class="kanban-page">
    <header class="kanban-page__header">
      <div class="kanban-page__title">
        <h1>Kanban</h1>
        <p v-if="currentPipeline">{{ currentPipeline.name }}</p>
      </div>
      <div class="kanban-page__actions">
        <select
          v-if="pipelines.length > 1"
          v-model="selectedPipelineId"
          class="kanban-page__select"
          @change="onPipelineChange"
        >
          <option
            v-for="pipeline in pipelines"
            :key="pipeline.id"
            :value="pipeline.id"
          >
            {{ pipeline.name }}
          </option>
        </select>
        <button
          class="kanban-page__button"
          @click="openSettings"
        >
          ⚙️ Configurações
        </button>
      </div>
    </header>

    <div
      v-if="uiFlags.isLoading"
      class="kanban-page__loading"
    >
      <spinner />
      <span>Carregando...</span>
    </div>

    <div
      v-else-if="!currentPipeline"
      class="kanban-page__empty"
    >
      <p>Nenhum pipeline encontrado.</p>
      <button
        class="kanban-page__button kanban-page__button--primary"
        @click="openSettings"
      >
        + Criar Pipeline
      </button>
    </div>

    <KanbanBoard
      v-else
      :board="board"
      :pipeline-type="currentPipeline?.pipeline_type || 'conversations'"
      @move="handleMove"
      @card-click="handleCardClick"
    />

    <KanbanSettingsModal
      v-if="showSettings"
      :pipeline="currentPipeline"
      :pipelines="pipelines"
      @close="showSettings = false"
      @saved="onSettingsSaved"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import KanbanBoard from 'dashboard/components/kanban/KanbanBoard.vue';
import KanbanSettingsModal from './KanbanSettingsModal.vue';

export default {
  name: 'KanbanIndex',
  components: {
    Spinner,
    KanbanBoard,
    KanbanSettingsModal,
  },
  data() {
    return {
      selectedPipelineId: null,
      showSettings: false,
    };
  },
  computed: {
    ...mapGetters('kanban', [
      'getPipelines',
      'getCurrentPipeline',
      'getBoard',
      'getUIFlags',
    ]),
    pipelines() {
      return this.getPipelines;
    },
    currentPipeline() {
      return this.getCurrentPipeline;
    },
    board() {
      return this.getBoard;
    },
    uiFlags() {
      return this.getUIFlags;
    },
    accountId() {
      return this.$route.params.accountId;
    },
  },
  watch: {
    accountId: {
      immediate: true,
      handler() {
        this.loadPipelines();
      },
    },
  },
  methods: {
    ...mapActions('kanban', [
      'fetchPipelines',
      'fetchBoard',
      'moveItem',
    ]),
    async loadPipelines() {
      await this.fetchPipelines(this.accountId);
      if (this.pipelines.length > 0) {
        this.selectedPipelineId = this.pipelines[0].id;
        this.loadBoard();
      }
    },
    async loadBoard() {
      if (!this.selectedPipelineId) return;
      await this.fetchBoard({
        accountId: this.accountId,
        pipelineId: this.selectedPipelineId,
      });
    },
    onPipelineChange() {
      this.loadBoard();
    },
    async handleMove({ itemId, itemType, fromStageId, toStageId }) {
      if (fromStageId === toStageId) return;

      await this.moveItem({
        accountId: this.accountId,
        pipelineId: this.selectedPipelineId,
        itemType,
        itemId,
        fromStageId,
        toStageId,
      });
    },
    handleCardClick({ item, itemType }) {
      if (itemType === 'conversation') {
        this.$router.push({
          name: 'inbox_conversation',
          params: {
            accountId: this.accountId,
            conversation_id: item.id,
          },
        });
      } else {
        this.$router.push({
          name: 'contact_profile',
          params: {
            accountId: this.accountId,
            contactId: item.id,
          },
        });
      }
    },
    openSettings() {
      this.showSettings = true;
    },
    onSettingsSaved() {
      this.showSettings = false;
      this.loadPipelines();
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  background-color: var(--s-25);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-normal);
    background-color: var(--white);
    border-bottom: 1px solid var(--s-100);
  }

  &__title {
    h1 {
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-800);
      margin: 0;
    }

    p {
      font-size: var(--font-size-small);
      color: var(--s-500);
      margin: var(--space-micro) 0 0 0;
    }
  }

  &__actions {
    display: flex;
    align-items: center;
    gap: var(--space-small);
  }

  &__select {
    padding: var(--space-small) var(--space-normal);
    border-radius: var(--border-radius-normal);
    border: 1px solid var(--s-200);
    background-color: var(--white);
    color: var(--s-800);
    cursor: pointer;
  }

  &__button {
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
      border-color: var(--s-300);
    }

    &--primary {
      background-color: var(--w-500);
      border-color: var(--w-500);
      color: var(--white);

      &:hover {
        background-color: var(--w-600);
        border-color: var(--w-600);
      }
    }
  }

  &__loading,
  &__empty {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: var(--space-normal);
    color: var(--s-500);
  }

  &__empty p {
    font-size: var(--font-size-default);
    margin: 0;
  }
}
</style>
