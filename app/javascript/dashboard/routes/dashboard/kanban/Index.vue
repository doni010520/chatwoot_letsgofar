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
        <woot-button
          icon="settings"
          variant="smooth"
          color-scheme="secondary"
          @click="openSettings"
        >
          Configurações
        </woot-button>
      </div>
    </header>

    <div
      v-if="uiFlags.isLoading"
      class="kanban-page__loading"
    >
      <spinner />
      <span>Carregando...</span>
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
  @apply flex flex-col h-full bg-slate-25 dark:bg-slate-900;

  &__header {
    @apply flex items-center justify-between p-4 bg-white dark:bg-slate-800 border-b border-slate-100 dark:border-slate-700;
  }

  &__title {
    h1 {
      @apply text-xl font-bold text-slate-800 dark:text-slate-100;
    }

    p {
      @apply text-sm text-slate-500 dark:text-slate-400;
    }
  }

  &__actions {
    @apply flex items-center gap-3;
  }

  &__select {
    @apply px-3 py-2 rounded-md border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100;
  }

  &__loading {
    @apply flex-1 flex flex-col items-center justify-center gap-4 text-slate-500 dark:text-slate-400;
  }
}
</style>