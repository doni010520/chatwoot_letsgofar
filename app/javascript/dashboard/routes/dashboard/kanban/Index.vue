<template>
  <div class="kanban-page">
    <header class="kanban-page__header">
      <div class="kanban-page__title">
        <span class="kanban-page__icon">📊</span>
        <h1>CRM</h1>
        <span class="kanban-page__separator">·</span>
        <span class="kanban-page__pipeline-name">{{ currentPipeline?.name || 'Carregando...' }}</span>
      </div>
      <div class="kanban-page__actions">
        <!-- Toggle de Visualização -->
        <div class="view-toggle">
          <button
            class="view-toggle__btn"
            :class="{ 'view-toggle__btn--active': viewMode === 'kanban' }"
            @click="viewMode = 'kanban'"
            title="Visualização Kanban"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="5" height="18" rx="1"/>
              <rect x="10" y="3" width="5" height="12" rx="1"/>
              <rect x="17" y="3" width="5" height="8" rx="1"/>
            </svg>
          </button>
          <button
            class="view-toggle__btn"
            :class="{ 'view-toggle__btn--active': viewMode === 'list' }"
            @click="viewMode = 'list'"
            title="Visualização em Lista"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="8" y1="6" x2="21" y2="6"/>
              <line x1="8" y1="12" x2="21" y2="12"/>
              <line x1="8" y1="18" x2="21" y2="18"/>
              <line x1="3" y1="6" x2="3.01" y2="6"/>
              <line x1="3" y1="12" x2="3.01" y2="12"/>
              <line x1="3" y1="18" x2="3.01" y2="18"/>
            </svg>
          </button>
        </div>

        <select
          v-if="pipelines.length > 1"
          v-model="selectedPipelineId"
          class="kanban-page__btn kanban-page__select"
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
          v-if="viewMode === 'kanban'"
          class="kanban-page__btn"
          :class="{ 'kanban-page__btn--active': showFilters }"
          @click="showFilters = !showFilters"
        >
          <span class="icon">🔍</span>
          <span>Filtros</span>
          <span v-if="hasActiveFilters" class="filter-badge">●</span>
        </button>
        <button
          class="kanban-page__btn kanban-page__btn--purple"
          @click="showImportModal = true"
        >
          <span class="icon">📤</span>
          <span>Importar</span>
        </button>
        <button
          class="kanban-page__btn kanban-page__btn--green"
          :disabled="isExporting"
          @click="exportBoard"
        >
          <span class="icon">📥</span>
          <span>{{ isExporting ? 'Exportando...' : 'Exportar' }}</span>
        </button>
        <button
          class="kanban-page__btn kanban-page__btn--blue"
          @click="openDashboard"
        >
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </button>
        <button
          class="kanban-page__btn kanban-page__btn--yellow"
          @click="showAutomations = true"
        >
          <span class="icon">⚡</span>
          <span>Automações</span>
        </button>
      </div>
    </header>

    <!-- Filtros (apenas no modo Kanban) -->
    <KanbanFilters
      v-if="showFilters && currentPipeline && viewMode === 'kanban'"
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
      <!-- Indicador de resultados filtrados (apenas no modo Kanban) -->
      <div v-if="hasActiveFilters && viewMode === 'kanban'" class="kanban-page__filter-info">
        <span>Exibindo resultados filtrados</span>
        <span class="kanban-page__totals">
          {{ boardTotals.count }} cards · R$ {{ formatCurrency(boardTotals.value) }}
        </span>
      </div>

      <!-- Visualização Kanban -->
      <KanbanBoard
        v-if="viewMode === 'kanban'"
        :board="board"
        :pipeline-type="currentPipeline?.pipeline_type || 'conversations'"
        :custom-fields-config="customFieldsConfig"
        @move="handleMove"
        @card-click="handleCardClick"
        @mark-won="handleMarkWon"
        @mark-lost="handleMarkLost"
        @remove="handleRemove"
      />

      <!-- Visualização em Lista -->
      <KanbanListView
        v-else
        :board="board"
        :stages="currentPipeline?.kanban_stages || []"
        :assignees="availableFilters.assignees || []"
        @move="handleMove"
        @card-click="handleCardClick"
        @mark-won="handleMarkWon"
        @mark-lost="handleMarkLost"
        @remove="handleRemove"
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

    <!-- Modal wrapper para Automações -->
    <div v-if="showAutomations && currentPipeline" class="modal-overlay" @click.self="showAutomations = false">
      <div class="modal-content modal-content--full">
        <button class="modal-close" @click="showAutomations = false">✕</button>
        <KanbanAutomationsManager
          :pipeline-id="currentPipeline.id"
          :stages="currentPipeline.kanban_stages || []"
          :users="availableFilters.assignees || []"
          @close="showAutomations = false"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import KanbanBoard from 'dashboard/components/kanban/KanbanBoard.vue';
import KanbanFilters from 'dashboard/components/kanban/KanbanFilters.vue';
import KanbanListView from 'dashboard/components/kanban/KanbanListView.vue';
import KanbanSettingsModal from './KanbanSettingsModal.vue';
import KanbanImportModal from 'dashboard/components/kanban/KanbanImportModal.vue';
import KanbanAutomationsManager from 'dashboard/components/kanban/KanbanAutomationsManager.vue';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanIndex',
  components: {
    Spinner,
    KanbanBoard,
    KanbanFilters,
    KanbanListView,
    KanbanSettingsModal,
    KanbanImportModal,
    KanbanAutomationsManager,
  },
  data() {
    return {
      selectedPipelineId: null,
      showSettings: false,
      showFilters: false,
      showImportModal: false,
      showAutomations: false,
      isExporting: false,
      viewMode: 'kanban', // 'kanban' ou 'list'
      activeFilters: {},
      availableFilters: {
        assignees: [],
        custom_fields: [],
      },
      customFieldsConfig: [],
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
    isAdmin() {
      return this.$store.getters.getCurrentRole === 'administrator';
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
  mounted() {
    // Recupera a preferência de visualização salva
    const savedViewMode = localStorage.getItem('crm_view_mode');
    if (savedViewMode && ['kanban', 'list'].includes(savedViewMode)) {
      this.viewMode = savedViewMode;
    }
  },
  methods: {
    ...mapActions('kanban', [
      'fetchPipelines',
      'fetchBoard',
      'moveItem',
      'markAsWon',
      'markAsLost',
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

      if (response) {
        if (response.available_filters) {
          this.availableFilters = response.available_filters;
        }
        if (response.totals) {
          this.boardTotals = response.totals;
        }
        if (response.custom_fields_config) {
          this.customFieldsConfig = response.custom_fields_config;
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
    async handleMarkWon({ itemId }) {
      try {
        await this.markAsWon({
          accountId: this.accountId,
          conversationId: itemId,
        });
      } catch (error) {
        console.error('Erro ao marcar como ganho:', error);
      }
    },
    async handleMarkLost({ itemId, reason }) {
      try {
        await this.markAsLost({
          accountId: this.accountId,
          conversationId: itemId,
          reason,
        });
      } catch (error) {
        console.error('Erro ao marcar como perdido:', error);
      }
    },
    async handleRemove({ itemId, itemType }) {
      try {
        await KanbanAPI.updateConversationStage(this.accountId, itemId, null);
        this.loadBoard();
      } catch (error) {
        console.error('Erro ao remover do CRM:', error);
      }
    },
    async exportBoard() {
      if (!this.selectedPipelineId || this.isExporting) return;
      
      this.isExporting = true;
      try {
        const response = await KanbanAPI.exportBoard(this.accountId, this.selectedPipelineId);
        
        const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        
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
  watch: {
    viewMode(newVal) {
      // Salva a preferência de visualização
      localStorage.setItem('crm_view_mode', newVal);
    },
    accountId: {
      immediate: true,
      handler() {
        this.loadPipelines();
      },
    },
  },
};
</script>

<style lang="scss" scoped>
.kanban-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
  background-color: var(--s-25);
  overflow: auto;

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
    padding: 12px 24px;
    background-color: var(--white);
    border-bottom: 1px solid var(--s-100);
    min-height: 60px;
    flex-shrink: 0;
    margin-bottom: 8px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-shrink: 0;

    h1 {
      font-size: 18px;
      font-weight: 700;
      color: var(--s-800);
      margin: 0;
    }
  }

  &__icon {
    font-size: 20px;
  }

  &__separator {
    color: var(--s-300);
    font-size: 20px;
    font-weight: 300;
  }

  &__pipeline-name {
    font-size: 18px;
    font-weight: 600;
    color: var(--s-600);
  }

  &__actions {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 8px;
  }

  /* Toggle de Visualização */
  .view-toggle {
    display: flex;
    align-items: center;
    background: var(--s-100);
    border-radius: 8px;
    padding: 2px;
    margin-right: 8px;

    &__btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 32px;
      border: none;
      background: transparent;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;

      svg {
        width: 18px;
        height: 18px;
        color: var(--s-500);
      }

      &:hover {
        background: var(--s-200);

        svg {
          color: var(--s-700);
        }
      }

      &--active {
        background: var(--white);
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

        svg {
          color: var(--w-500);
        }

        &:hover {
          background: var(--white);
        }
      }
    }
  }

  /* Estilo Glass para todos os botões */
  &__btn {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
    position: relative;
    
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.3);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    color: var(--s-700);

    &:hover {
      background: rgba(255, 255, 255, 0.9);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      transform: translateY(-1px);
    }

    &--active {
      background: rgba(59, 130, 246, 0.15);
      border-color: rgba(59, 130, 246, 0.3);
      color: #2563eb;
    }

    &--purple {
      background: rgba(139, 92, 246, 0.1);
      border-color: rgba(139, 92, 246, 0.25);
      color: #7c3aed;

      &:hover {
        background: rgba(139, 92, 246, 0.2);
        border-color: rgba(139, 92, 246, 0.4);
      }
    }

    &--green {
      background: rgba(16, 185, 129, 0.1);
      border-color: rgba(16, 185, 129, 0.25);
      color: #059669;

      &:hover {
        background: rgba(16, 185, 129, 0.2);
        border-color: rgba(16, 185, 129, 0.4);
      }
    }

    &--blue {
      background: rgba(59, 130, 246, 0.15);
      border-color: rgba(59, 130, 246, 0.3);
      color: #2563eb;

      &:hover {
        background: rgba(59, 130, 246, 0.25);
        border-color: rgba(59, 130, 246, 0.5);
      }
    }

    &--yellow {
      background: rgba(245, 158, 11, 0.1);
      border-color: rgba(245, 158, 11, 0.25);
      color: #d97706;

      &:hover {
        background: rgba(245, 158, 11, 0.2);
        border-color: rgba(245, 158, 11, 0.4);
      }
    }

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
      transform: none;
    }

    .icon {
      font-size: 14px;
    }

    .filter-badge {
      color: #ef4444;
      font-size: 10px;
      margin-left: -2px;
    }
  }

  &__select {
    min-width: 140px;
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 10px center;
    padding-right: 30px;
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

/* Modal para Automações */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: var(--white);
  border-radius: 12px;
  position: relative;
  max-height: 90vh;
  overflow: auto;

  &--full {
    width: 95%;
    max-width: 1400px;
    height: 90vh;
  }
}

.modal-close {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 32px;
  height: 32px;
  border: none;
  background: var(--s-100);
  border-radius: 50%;
  font-size: 18px;
  cursor: pointer;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--s-600);

  &:hover {
    background: var(--s-200);
    color: var(--s-800);
  }
}

/* Dark mode */
.dark .kanban-page {
  &__header {
    background-color: #1a1d26;
    border-bottom-color: #2d3343;
  }

  &__title {
    h1 {
      color: var(--s-100);
    }
  }

  &__separator {
    color: var(--s-600);
  }

  &__pipeline-name {
    color: var(--s-300);
  }

  .view-toggle {
    background: var(--s-800);

    &__btn {
      svg {
        color: var(--s-400);
      }

      &:hover {
        background: var(--s-700);

        svg {
          color: var(--s-200);
        }
      }

      &--active {
        background: var(--s-700);

        svg {
          color: var(--w-400);
        }
      }
    }
  }

  &__btn {
    background: rgba(30, 35, 45, 0.8);
    border-color: rgba(60, 70, 85, 0.5);
    color: var(--s-200);

    &:hover {
      background: rgba(40, 45, 55, 0.9);
      border-color: rgba(70, 80, 95, 0.6);
    }

    &--active {
      background: rgba(59, 130, 246, 0.2);
      border-color: rgba(59, 130, 246, 0.4);
      color: #60a5fa;
    }

    &--purple {
      background: rgba(139, 92, 246, 0.15);
      border-color: rgba(139, 92, 246, 0.3);
      color: #a78bfa;
    }

    &--green {
      background: rgba(16, 185, 129, 0.15);
      border-color: rgba(16, 185, 129, 0.3);
      color: #34d399;
    }

    &--blue {
      background: rgba(59, 130, 246, 0.2);
      border-color: rgba(59, 130, 246, 0.4);
      color: #60a5fa;
    }

    &--yellow {
      background: rgba(245, 158, 11, 0.15);
      border-color: rgba(245, 158, 11, 0.3);
      color: #fbbf24;
    }
  }

  &__filter-info {
    background-color: rgba(59, 130, 246, 0.1);
    border-bottom-color: rgba(59, 130, 246, 0.2);
    color: #60a5fa;
  }

  .modal-content {
    background: var(--s-900);
  }

  .modal-close {
    background: var(--s-700);
    color: var(--s-300);

    &:hover {
      background: var(--s-600);
    }
  }
}
</style>


