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
          class="kanban-page__config-btn"
          @click="openSettings"
        >
          <span class="icon">⚙️</span>
          <span>Configurações</span>
        </button>
      </div>
    </header>

    <div v-if="uiFlags.isLoading" class="kanban-page__loading">
      <spinner />
      <span>Carregando...</span>
    </div>

    <div v-else-if="!currentPipeline" class="kanban-page__empty">
      <div class="kanban-page__empty-content">
        <h2>Nenhum pipeline encontrado</h2>
        <p>Crie seu primeiro pipeline para começar a organizar seus leads.</p>
        <button class="kanban-page__create-btn" @click="openSettings">
          + Criar Pipeline
        </button>
      </div>
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
    padding: 16px 24px;
    background-color: var(--white);
    border-bottom: 1px solid var(--s-100);
  }

  &__title {
    h1 {
      font-size: 20px;
      font-weight: 700;
      color: var(--s-800);
      margin: 0;
    }

    p {
      font-size: 13px;
      color: var(--s-500);
      margin: 4px 0 0 0;
    }
  }

  &__actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  &__select {
    padding: 8px 12px;
    border-radius: 6px;
    border: 1px solid var(--s-200);
    background-color: var(--white);
    color: var(--s-800);
    font-size: 14px;
    cursor: pointer;
    outline: none;

    &:focus {
      border-color: var(--w-500);
    }
  }

  &__config-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    border: 1px solid var(--s-200);
    background-color: var(--white);
    color: var(--s-700);
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;

    &:hover {
      background-color: var(--s-50);
      border-color: var(--s-300);
    }

    .icon {
      font-size: 16px;
    }
  }

  &__loading {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16px;
    color: var(--s-500);
  }

  &__empty {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  &__empty-content {
    text-align: center;
    padding: 40px;

    h2 {
      font-size: 18px;
      font-weight: 600;
      color: var(--s-800);
      margin: 0 0 8px 0;
    }

    p {
      font-size: 14px;
      color: var(--s-500);
      margin: 0 0 24px 0;
    }
  }

  &__create-btn {
    padding: 12px 24px;
    border-radius: 6px;
    border: none;
    background-color: var(--w-500);
    color: var(--white);
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;

    &:hover {
      background-color: var(--w-600);
    }
  }
}
</style>
