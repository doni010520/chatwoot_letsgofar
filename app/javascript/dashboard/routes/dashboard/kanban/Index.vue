<template>
  <div class="kanban-page">
    <header class="kanban-page__header">
      <div class="kanban-page__title">
        <h1>CRM</h1>
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
          class="kanban-page__filter-btn"
          :class="{ 'kanban-page__filter-btn--active': showFilters }"
          @click="showFilters = !showFilters"
        >
          <span class="icon">🔍</span>
          <span>Filtros</span>
          <span v-if="hasActiveFilters" class="filter-badge">●</span>
        </button>
        <button
          class="kanban-page__import-btn"
          @click="showImportModal = true"
        >
          <span class="icon">📤</span>
          <span>Importar</span>
        </button>
        <button
          class="kanban-page__export-btn"
          :disabled="isExporting"
          @click="exportBoard"
        >
          <span class="icon">📥</span>
          <span>{{ isExporting ? 'Exportando...' : 'Exportar' }}</span>
        </button>
        <button
          class="kanban-page__dashboard-btn"
          @click="openDashboard"
        >
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </button>
        <button
          class="kanban-page__config-btn"
          @click="openSettings"
        >
          <span class="icon">⚙️</span>
          <span>Configurações</span>
        </button>
      </div>
    </header>

    <!-- Filtros -->
    <KanbanFilters
      v-if="showFilters && currentPipeline"
      :assignees="availableFilters.assignees"
      :custom-fields="availableFilters.custom_fields"
      :filters="activeFilters"
      @filter-change="onFilterChange"
    />

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

    <template v-else>
      <!-- Indicador de resultados filtrados -->
      <div v-if="hasActiveFilters" class="kanban-page__filter-info">
        <span>Exibindo resultados filtrados</span>
        <span class="kanban-page__totals">
          {{ boardTotals.count }} cards · R$ {{ formatCurrency(boardTotals.value) }}
        </span>
      </div>

      <KanbanBoard
        :board="board"
        :pipeline-type="currentPipeline?.pipeline_type || 'conversations'"
        :custom-fields-config="availableFilters.custom_fields"
        @move="handleMove"
        @card-click="handleCardClick"
      />
    </template>

    <KanbanSettingsModal
      v-if="showSettings"
      :pipeline="currentPipeline"
      :pipelines="pipelines"
      @close="showSettings = false"
      @saved="onSettingsSaved"
    />

    <KanbanImportModal
      v-if="showImportModal && currentPipeline"
      :pipeline-id="currentPipeline.id"
      :stages="currentPipeline.kanban_stages || []"
      @close="showImportModal = false"
      @imported="onImportCompleted"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import KanbanBoard from 'dashboard/components/kanban/KanbanBoard.vue';
import KanbanFilters from 'dashboard/components/kanban/KanbanFilters.vue';
import KanbanSettingsModal from './KanbanSettingsModal.vue';
import KanbanImportModal from 'dashboard/components/kanban/KanbanImportModal.vue';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanIndex',
  components: {
    Spinner,
    KanbanBoard,
    KanbanFilters,
    KanbanSettingsModal,
    KanbanImportModal,
  },
  data() {
    return {
      selectedPipelineId: null,
      showSettings: false,
      showFilters: false,
      showImportModal: false,
      isExporting: false,
      activeFilters: {},
      availableFilters: {
        assignees: [],
        custom_fields: [],
      },
      boardTotals: {
        count: 0,
        value: 0,
      },
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
    hasActiveFilters() {
      return Object.keys(this.activeFilters).some(key => this.activeFilters[key]);
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
      
      const response = await this.fetchBoard({
        accountId: this.accountId,
        pipelineId: this.selectedPipelineId,
        filters: this.activeFilters,
      });

      // Atualizar filtros disponíveis e totais
      if (response) {
        if (response.available_filters) {
          this.availableFilters = response.available_filters;
        }
        if (response.totals) {
          this.boardTotals = response.totals;
        }
      }
    },
    onPipelineChange() {
      this.activeFilters = {};
      this.loadBoard();
    },
    onFilterChange(filters) {
      this.activeFilters = filters;
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
    async exportBoard() {
      if (!this.selectedPipelineId || this.isExporting) return;
      
      this.isExporting = true;
      try {
        const response = await KanbanAPI.exportBoard(this.accountId, this.selectedPipelineId);
        
        // Criar blob e fazer download
        const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        
        // Nome do arquivo baseado no pipeline
        const pipelineName = this.currentPipeline?.name || 'kanban';
        const date = new Date().toISOString().split('T')[0];
        link.setAttribute('download', `${pipelineName.toLowerCase().replace(/\s+/g, '_')}_${date}.csv`);
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      } catch (error) {
        console.error('Erro ao exportar:', error);
      } finally {
        this.isExporting = false;
      }
    },
    onImportCompleted() {
      this.showImportModal = false;
      this.loadBoard();
    },
    openSettings() {
      this.showSettings = true;
    },
    openDashboard() {
      this.$router.push({
        name: 'kanban_dashboard',
        params: {
          accountId: this.accountId,
        },
      });
    },
    onSettingsSaved() {
      this.showSettings = false;
      this.loadPipelines();
    },
    formatCurrency(value) {
      return Number(value || 0).toLocaleString('pt-BR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
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

  &__filter-btn {
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
    position: relative;

    &:hover {
      background-color: var(--s-50);
      border-color: var(--s-300);
    }

    &--active {
      background-color: #eff6ff;
      border-color: #3b82f6;
      color: #3b82f6;
    }

    .icon {
      font-size: 16px;
    }

    .filter-badge {
      color: #ef4444;
      font-size: 10px;
      margin-left: -4px;
    }
  }

  &__import-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    border: 1px solid #8b5cf6;
    background-color: #f5f3ff;
    color: #6d28d9;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;

    &:hover {
      background-color: #ede9fe;
      border-color: #7c3aed;
    }

    .icon {
      font-size: 16px;
    }
  }

  &__export-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    border: 1px solid #10b981;
    background-color: #ecfdf5;
    color: #065f46;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;

    &:hover:not(:disabled) {
      background-color: #d1fae5;
      border-color: #059669;
    }

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .icon {
      font-size: 16px;
    }
  }

  &__dashboard-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    border: none;
    background-color: #3b82f6;
    color: white;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;

    &:hover {
      background-color: #2563eb;
    }

    .icon {
      font-size: 16px;
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

  &__filter-info {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 24px;
    background-color: #eff6ff;
    border-bottom: 1px solid #bfdbfe;
    font-size: 13px;
    color: #1e40af;
  }

  &__totals {
    font-weight: 600;
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

