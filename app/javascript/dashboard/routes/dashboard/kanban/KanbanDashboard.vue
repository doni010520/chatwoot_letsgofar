<template>
  <div class="kanban-dashboard">
    <!-- Header -->
    <div class="dashboard-header">
      <div class="dashboard-header__left">
        <button class="dashboard-header__back" @click="goBack" title="Voltar ao CRM">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 12H5"/><path d="m12 19-7-7 7-7"/>
          </svg>
        </button>
        <h1 class="dashboard-header__title">
          <svg class="dashboard-header__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 3v18h18"/><path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"/>
          </svg>
          {{ activeTab === 'vendas' ? 'Dashboard de Vendas' : 'Controle de Leads' }}
        </h1>
      </div>
      <div class="dashboard-header__filters">
        <select v-model="selectedPipelineId" class="dashboard-select" @change="loadData">
          <option v-for="p in pipelines" :key="p.id" :value="p.id">{{ p.name }}</option>
        </select>
        <select v-model="selectedPeriod" class="dashboard-select" @change="loadData">
          <option value="7">Últimos 7 dias</option>
          <option value="30">Últimos 30 dias</option>
          <option value="60">Últimos 60 dias</option>
          <option value="90">Últimos 90 dias</option>
        </select>
      </div>
    </div>

    <!-- Tab Navigation -->
    <div class="dashboard-tabs">
      <button
        class="dashboard-tabs__btn"
        :class="{ 'dashboard-tabs__btn--active': activeTab === 'vendas' }"
        @click="switchTab('vendas')"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <path d="M3 3v18h18"/><path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"/>
        </svg>
        Dashboard de Vendas
      </button>
      <button
        class="dashboard-tabs__btn"
        :class="{ 'dashboard-tabs__btn--active': activeTab === 'leads' }"
        @click="switchTab('leads')"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
          <circle cx="9" cy="7" r="4"/>
          <path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        Controle de Leads
      </button>
    </div>

    <!-- Leads Tab -->
    <template v-if="activeTab === 'leads'">
      <LeadControlDashboard
        :report="leadReport"
        :is-loading="isLeadLoading"
      />
    </template>

    <!-- Sales Tab - Loading -->
    <div v-else-if="isLoading" class="dashboard-loading">
      <div class="loading-spinner"></div>
      <span>Carregando dados...</span>
    </div>

    <template v-else-if="summary">
      <!-- Métricas principais -->
      <div class="metrics-grid">
        <div class="metric-card">
          <div class="metric-card__icon metric-card__icon--blue">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
            </svg>
          </div>
          <div class="metric-card__content">
            <div class="metric-card__label">Total em Negociação</div>
            <div class="metric-card__value metric-card__value--blue">
              {{ formatCurrency(summary.totals.open_value) }}
            </div>
            <div class="metric-card__sub">{{ summary.totals.open_count }} negócios ativos</div>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-card__icon metric-card__icon--green">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <div class="metric-card__content">
            <div class="metric-card__label">Ganhos no Período</div>
            <div class="metric-card__value metric-card__value--green">
              {{ formatCurrency(summary.totals.won_value) }}
            </div>
            <div class="metric-card__sub">{{ summary.totals.won_count }} negócios fechados</div>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-card__icon metric-card__icon--red">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </div>
          <div class="metric-card__content">
            <div class="metric-card__label">Perdidos no Período</div>
            <div class="metric-card__value metric-card__value--red">
              {{ formatCurrency(summary.totals.lost_value) }}
            </div>
            <div class="metric-card__sub">{{ summary.totals.lost_count }} negócios perdidos</div>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-card__icon metric-card__icon--yellow">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/>
            </svg>
          </div>
          <div class="metric-card__content">
            <div class="metric-card__label">Taxa de Conversão</div>
            <div class="metric-card__value metric-card__value--yellow">
              {{ summary.totals.conversion_rate }}%
            </div>
            <div class="metric-card__sub">
              {{ summary.totals.won_count }} / {{ summary.totals.won_count + summary.totals.lost_count }} fechados
            </div>
          </div>
        </div>
      </div>

      <!-- Grid principal -->
      <div class="main-grid">
        <!-- Funil de vendas -->
        <div class="card">
          <div class="card__title">
            <svg class="card__title-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>
            </svg>
            Funil de Vendas
          </div>
          <div class="funnel">
            <div v-for="(stage, index) in summary.funnel" :key="stage.stage_id" class="funnel-stage">
              <div class="funnel-stage__color" :style="{ backgroundColor: stage.stage_color }"></div>
              <div class="funnel-stage__name">{{ stage.stage_name }}</div>
              <div class="funnel-stage__bar-container">
                <div
                  class="funnel-stage__bar"
                  :style="{
                    width: getBarWidth(stage.count) + '%',
                    backgroundColor: stage.stage_color
                  }"
                >
                  <span class="funnel-stage__bar-text">{{ stage.count }}</span>
                </div>
              </div>
              <div class="funnel-stage__values">
                <span class="funnel-stage__value">{{ formatCurrency(stage.value) }}</span>
              </div>
              <div class="funnel-stage__conversion">
                <template v-if="index > 0 && summary.stage_conversions[index - 1]">
                  <span class="conversion-badge">{{ summary.stage_conversions[index - 1].conversion_rate }}%</span>
                </template>
              </div>
            </div>
          </div>
        </div>

        <!-- Motivos de perda -->
        <div class="card">
          <div class="card__title">
            <svg class="card__title-icon card__title-icon--red" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
            </svg>
            Motivos de Perda
          </div>
          <div v-if="lossReasons && lossReasons.reasons.length > 0" class="loss-reasons">
            <div v-for="reason in lossReasons.reasons" :key="reason.reason" class="loss-reason">
              <div class="loss-reason__name">{{ reason.reason }}</div>
              <div class="loss-reason__bar-container">
                <div class="loss-reason__bar" :style="{ width: reason.percentage + '%' }">
                  <span>{{ reason.count }}</span>
                </div>
              </div>
              <div class="loss-reason__percent">{{ reason.percentage }}%</div>
            </div>
          </div>
          <div v-else class="empty-state">
            <svg class="empty-state__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M5.8 11.3 2 22l10.7-3.79"/><path d="M4 3h.01"/><path d="M22 8h.01"/><path d="M15 2h.01"/><path d="M22 20h.01"/><path d="m22 2-2.24.75a2.9 2.9 0 0 0-1.96 3.12v0c.1.86-.57 1.63-1.45 1.63h-.38c-.86 0-1.6.6-1.76 1.44L14 10"/><path d="m22 13-.82-.33c-.86-.34-1.82.2-1.98 1.11v0c-.11.7-.72 1.22-1.43 1.22H17"/><path d="m11 2 .33.82c.34.86-.2 1.82-1.11 1.98v0C9.52 4.9 9 5.52 9 6.23V7"/><path d="M11 13c1.93 1.93 2.83 4.17 2 5-.83.83-3.07-.07-5-2-1.93-1.93-2.83-4.17-2-5 .83-.83 3.07.07 5 2Z"/>
            </svg>
            <span>Nenhuma perda registrada no período</span>
          </div>
        </div>
      </div>

      <!-- Grid secundário -->
      <div class="secondary-grid">
        <!-- Top performers -->
        <div class="card">
          <div class="card__title">
            <svg class="card__title-icon card__title-icon--yellow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/>
            </svg>
            Top Vendedores
          </div>
          <div v-if="topPerformers && topPerformers.performers.length > 0" class="performers">
            <div v-for="(performer, index) in topPerformers.performers" :key="performer.id" class="performer">
              <div class="performer__rank" :class="`performer__rank--${index + 1}`">
                {{ index + 1 }}
              </div>
              <div class="performer__avatar" :class="`performer__avatar--${index + 1}`">
                {{ getInitials(performer.name) }}
              </div>
              <div class="performer__info">
                <div class="performer__name">{{ performer.name }}</div>
                <div class="performer__count">{{ performer.won_count }} vendas fechadas</div>
              </div>
              <div class="performer__value">{{ formatCurrency(performer.total_value) }}</div>
            </div>
          </div>
          <div v-else class="empty-state">
            <svg class="empty-state__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>
            </svg>
            <span>Nenhuma venda fechada no período</span>
          </div>
        </div>

        <!-- Conversão entre estágios -->
        <div class="card">
          <div class="card__title">
            <svg class="card__title-icon card__title-icon--green" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/>
            </svg>
            Conversão entre Estágios
          </div>
          <div v-if="summary.stage_conversions.length > 0" class="conversions">
            <div v-for="conv in summary.stage_conversions" :key="conv.from_stage + conv.to_stage" class="conversion">
              <div class="conversion__flow">
                <span class="conversion__stage">{{ conv.from_stage }}</span>
                <svg class="conversion__arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                </svg>
                <span class="conversion__stage">{{ conv.to_stage }}</span>
              </div>
              <span class="conversion__rate" :class="getConversionClass(conv.conversion_rate)">
                {{ conv.conversion_rate }}%
              </span>
            </div>
            <div class="conversion conversion--total">
              <div class="conversion__flow">
                <span class="conversion__stage"><strong>Total</strong></span>
                <svg class="conversion__arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                </svg>
                <span class="conversion__stage">Lead → Venda</span>
              </div>
              <span class="conversion__rate conversion__rate--total" :class="getConversionClass(summary.totals.conversion_rate)">
                {{ summary.totals.conversion_rate }}%
              </span>
            </div>
          </div>
          <div v-else class="empty-state">
            <svg class="empty-state__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
            </svg>
            <span>Dados insuficientes</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';
import LeadControlDashboard from './LeadControlDashboard.vue';

export default {
  name: 'KanbanDashboard',
  components: {
    LeadControlDashboard,
  },
  setup() {
    const route = useRoute();
    const store = useStore();

    const pipelines = ref([]);
    const selectedPipelineId = ref(null);
    const selectedPeriod = ref('30');
    const isLoading = ref(true);
    const summary = ref(null);
    const lossReasons = ref(null);
    const topPerformers = ref(null);
    const activeTab = ref('vendas');
    const leadReport = ref(null);
    const isLeadLoading = ref(false);

    const accountId = computed(() => route.params.accountId);

    const getDateRange = () => {
      const endDate = new Date().toISOString().split('T')[0];
      const startDate = new Date(Date.now() - parseInt(selectedPeriod.value) * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];
      return { startDate, endDate };
    };

    const loadPipelines = async () => {
      try {
        const response = await KanbanAPI.getPipelines(accountId.value);
        pipelines.value = response.data.filter(p => p.pipeline_type === 'conversations');
        if (pipelines.value.length > 0) {
          selectedPipelineId.value = pipelines.value[0].id;
          await loadData();
        }
      } catch (error) {
        console.error('Erro ao carregar pipelines:', error);
      }
    };

    const loadData = async () => {
      if (!selectedPipelineId.value) return;

      isLoading.value = true;
      const { startDate, endDate } = getDateRange();

      try {
        const [summaryRes, lossRes, performersRes] = await Promise.all([
          KanbanAPI.getReportSummary(accountId.value, selectedPipelineId.value, startDate, endDate),
          KanbanAPI.getLossReasons(accountId.value, selectedPipelineId.value, startDate, endDate),
          KanbanAPI.getTopPerformers(accountId.value, selectedPipelineId.value, startDate, endDate),
        ]);

        summary.value = summaryRes.data;
        lossReasons.value = lossRes.data;
        topPerformers.value = performersRes.data;
      } catch (error) {
        console.error('Erro ao carregar dados:', error);
      } finally {
        isLoading.value = false;
      }

      // Also reload lead report if it was previously loaded
      if (leadReport.value || activeTab.value === 'leads') {
        loadLeadReport();
      }
    };

    const loadLeadReport = async () => {
      if (!selectedPipelineId.value) return;

      isLeadLoading.value = true;
      const { startDate, endDate } = getDateRange();

      try {
        const res = await KanbanAPI.getLeadReport(
          accountId.value,
          selectedPipelineId.value,
          startDate,
          endDate
        );
        leadReport.value = res.data;
      } catch (error) {
        console.error('Erro ao carregar relatório de leads:', error);
      } finally {
        isLeadLoading.value = false;
      }
    };

    const switchTab = (tab) => {
      activeTab.value = tab;
      if (tab === 'leads' && !leadReport.value) {
        loadLeadReport();
      }
    };

    const formatCurrency = (value) => {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      }).format(value || 0);
    };

    const getInitials = (name) => {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .substring(0, 2)
        .toUpperCase();
    };

    const getBarWidth = (count) => {
      if (!summary.value || !summary.value.funnel.length) return 0;
      const maxCount = Math.max(...summary.value.funnel.map(s => s.count));
      if (maxCount === 0) return 0;
      return Math.max(10, (count / maxCount) * 100);
    };

    const getConversionClass = (rate) => {
      if (rate >= 60) return 'conversion__rate--high';
      if (rate >= 40) return 'conversion__rate--medium';
      return 'conversion__rate--low';
    };

    const goBack = () => {
      window.history.back();
    };

    onMounted(() => {
      loadPipelines();
    });

    return {
      goBack,
      pipelines,
      selectedPipelineId,
      selectedPeriod,
      isLoading,
      summary,
      lossReasons,
      topPerformers,
      activeTab,
      leadReport,
      isLeadLoading,
      loadData,
      switchTab,
      formatCurrency,
      getInitials,
      getBarWidth,
      getConversionClass,
    };
  },
};
</script>

<style scoped>
/* ===== BASE ===== */
.kanban-dashboard {
  padding: 24px;
  height: 100%;
  overflow-y: auto;
  width: 100%;
  max-width: 1600px;
  margin: 0 auto;
  background-color: var(--s-25);
  color: var(--s-900);
}

/* ===== HEADER ===== */
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 20px 24px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.dashboard-header__left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.dashboard-header__back {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  border: 1px solid var(--s-200);
  background-color: var(--s-50);
  cursor: pointer;
  transition: all 0.2s ease;
}

.dashboard-header__back:hover {
  background-color: var(--s-100);
  border-color: var(--s-300);
}

.dashboard-header__back svg {
  width: 20px;
  height: 20px;
  color: var(--s-600);
}

.dashboard-header__title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 22px;
  font-weight: 700;
  color: var(--s-900);
}

.dashboard-header__icon {
  width: 28px;
  height: 28px;
  color: var(--w-500);
}

.dashboard-header__filters {
  display: flex;
  gap: 12px;
}

.dashboard-select {
  padding: 10px 16px;
  background-color: var(--s-50);
  border: 1px solid var(--s-200);
  border-radius: 10px;
  color: var(--s-800);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.dashboard-select:hover {
  border-color: var(--s-300);
}

.dashboard-select:focus {
  outline: none;
  border-color: var(--w-500);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* ===== TABS ===== */
.dashboard-tabs {
  display: flex;
  gap: 4px;
  padding: 4px;
  background-color: var(--white);
  border-radius: 14px;
  border: 1px solid var(--s-100);
  margin-bottom: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.dashboard-tabs__btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  border-radius: 10px;
  border: none;
  background-color: transparent;
  color: var(--s-500);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  flex: 1;
  justify-content: center;
}

.dashboard-tabs__btn:hover {
  color: var(--s-700);
  background-color: var(--s-50);
}

.dashboard-tabs__btn--active {
  background-color: var(--w-500);
  color: #fff;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.25);
}

.dashboard-tabs__btn--active:hover {
  background-color: var(--w-600, #2563eb);
  color: #fff;
}

.dashboard-tabs__btn svg {
  flex-shrink: 0;
}

/* ===== LOADING ===== */
.dashboard-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px;
  gap: 16px;
  color: var(--s-500);
  font-size: 16px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--s-200);
  border-top-color: var(--w-500);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ===== EMPTY STATE ===== */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 32px;
  color: var(--s-400);
  font-size: 14px;
  gap: 12px;
}

.empty-state__icon {
  width: 32px;
  height: 32px;
  opacity: 0.5;
}

/* ===== METRICS GRID ===== */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 24px;
}

.metric-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.metric-card__icon {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.metric-card__icon svg {
  width: 28px;
  height: 28px;
  color: white;
}

.metric-card__icon--blue { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); }
.metric-card__icon--green { background: linear-gradient(135deg, #10b981 0%, #059669 100%); }
.metric-card__icon--red { background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); }
.metric-card__icon--yellow { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); }

.metric-card__content {
  flex: 1;
  min-width: 0;
}

.metric-card__label {
  font-size: 12px;
  color: var(--s-500);
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 500;
}

.metric-card__value {
  font-size: 24px;
  font-weight: 700;
  line-height: 1.2;
}

.metric-card__value--green { color: #10b981; }
.metric-card__value--red { color: #ef4444; }
.metric-card__value--blue { color: #3b82f6; }
.metric-card__value--yellow { color: #f59e0b; }

.metric-card__sub {
  font-size: 12px;
  color: var(--s-400);
  margin-top: 4px;
}

/* ===== GRIDS ===== */
.main-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 24px;
  margin-bottom: 24px;
}

.secondary-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.card {
  padding: 24px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.card__title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 24px;
  color: var(--s-800);
}

.card__title-icon {
  width: 22px;
  height: 22px;
  color: var(--w-500);
}

.card__title-icon--red { color: #ef4444; }
.card__title-icon--yellow { color: #f59e0b; }
.card__title-icon--green { color: #10b981; }

/* ===== FUNNEL ===== */
.funnel {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.funnel-stage {
  display: flex;
  align-items: center;
  gap: 12px;
}

.funnel-stage__color {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  flex-shrink: 0;
}

.funnel-stage__name {
  width: 100px;
  font-size: 14px;
  color: var(--s-700);
  flex-shrink: 0;
  font-weight: 500;
}

.funnel-stage__bar-container {
  flex: 1;
  height: 36px;
  background-color: var(--s-100);
  border-radius: 8px;
  overflow: hidden;
  min-width: 80px;
}

.funnel-stage__bar {
  height: 100%;
  border-radius: 8px;
  display: flex;
  align-items: center;
  padding: 0 14px;
  transition: width 0.5s ease;
}

.funnel-stage__bar-text {
  font-size: 13px;
  font-weight: 600;
  color: #fff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.funnel-stage__values {
  width: 100px;
  text-align: right;
  flex-shrink: 0;
}

.funnel-stage__value {
  font-size: 13px;
  font-weight: 600;
  color: #10b981;
}

.funnel-stage__conversion {
  width: 60px;
  text-align: center;
  flex-shrink: 0;
}

.conversion-badge {
  display: inline-block;
  padding: 4px 10px;
  background-color: var(--s-100);
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
  color: var(--s-600);
}

/* ===== LOSS REASONS ===== */
.loss-reasons {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.loss-reason {
  display: flex;
  align-items: center;
  gap: 12px;
}

.loss-reason__name {
  width: 100px;
  font-size: 13px;
  color: var(--s-600);
  flex-shrink: 0;
  font-weight: 500;
}

.loss-reason__bar-container {
  flex: 1;
  height: 28px;
  background-color: var(--s-100);
  border-radius: 6px;
  overflow: hidden;
  min-width: 40px;
}

.loss-reason__bar {
  height: 100%;
  background: linear-gradient(90deg, #ef4444, #f87171);
  border-radius: 6px;
  display: flex;
  align-items: center;
  padding-left: 10px;
  font-size: 12px;
  font-weight: 500;
  color: #fff;
  transition: width 0.5s ease;
}

.loss-reason__percent {
  width: 50px;
  text-align: right;
  font-size: 13px;
  font-weight: 600;
  color: var(--s-500);
  flex-shrink: 0;
}

/* ===== PERFORMERS ===== */
.performers {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.performer {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px;
  background-color: var(--s-50);
  border-radius: 12px;
  transition: all 0.2s ease;
}

.performer:hover {
  background-color: var(--s-100);
  transform: translateX(4px);
}

.performer__rank {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  flex-shrink: 0;
  background-color: var(--s-200);
  color: var(--s-600);
}

.performer__rank--1 { 
  background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); 
  color: #1a1a2e; 
}
.performer__rank--2 { 
  background: linear-gradient(135deg, #9ca3af 0%, #d1d5db 100%); 
  color: #1a1a2e; 
}
.performer__rank--3 { 
  background: linear-gradient(135deg, #b45309 0%, #d97706 100%); 
  color: #fff; 
}

.performer__avatar {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 600;
  flex-shrink: 0;
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: #fff;
}

.performer__avatar--1 { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: #1a1a2e; }
.performer__avatar--2 { background: linear-gradient(135deg, #10b981 0%, #059669 100%); }
.performer__avatar--3 { background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); }

.performer__info {
  flex: 1;
  min-width: 0;
}

.performer__name {
  font-size: 14px;
  font-weight: 600;
  color: var(--s-800);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.performer__count {
  font-size: 12px;
  color: var(--s-500);
  margin-top: 2px;
}

.performer__value {
  font-size: 15px;
  font-weight: 700;
  color: #10b981;
  flex-shrink: 0;
}

/* ===== CONVERSIONS ===== */
.conversions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.conversion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
  background-color: var(--s-50);
  border-radius: 10px;
  transition: all 0.2s ease;
}

.conversion:hover {
  background-color: var(--s-100);
}

.conversion--total {
  margin-top: 8px;
  background-color: rgba(59, 130, 246, 0.1);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.conversion__flow {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.conversion__stage {
  color: var(--s-700);
}

.conversion__arrow {
  width: 16px;
  height: 16px;
  color: var(--s-400);
}

.conversion__rate {
  padding: 5px 12px;
  border-radius: 20px;
  font-weight: 600;
  font-size: 12px;
}

.conversion__rate--high { 
  background-color: rgba(16, 185, 129, 0.15); 
  color: #059669; 
}
.conversion__rate--medium { 
  background-color: rgba(245, 158, 11, 0.15); 
  color: #d97706; 
}
.conversion__rate--low { 
  background-color: rgba(239, 68, 68, 0.15); 
  color: #dc2626; 
}

.conversion__rate--total {
  font-size: 14px;
  padding: 6px 16px;
}

/* ===== RESPONSIVE ===== */
@media (max-width: 1200px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .main-grid,
  .secondary-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .kanban-dashboard {
    padding: 16px;
  }
  
  .dashboard-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  
  .metrics-grid {
    grid-template-columns: 1fr;
  }
  
  .metric-card__value {
    font-size: 20px;
  }
  
  .funnel-stage__name {
    width: 70px;
    font-size: 12px;
  }
  
  .funnel-stage__values {
    width: 80px;
  }
}

/* ===== DARK MODE ===== */
.dark .kanban-dashboard {
  background-color: #0f1117;
  color: var(--s-100);
}

.dark .dashboard-header {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
}

.dark .dashboard-header__back {
  background-color: #252a36;
  border-color: #3d4455;
}

.dark .dashboard-header__back:hover {
  background-color: #2d3343;
  border-color: #4d5566;
}

.dark .dashboard-header__back svg {
  color: #a5b4c5;
}

.dark .dashboard-header__title {
  color: var(--s-100);
}

.dark .dashboard-tabs {
  background-color: #1a1d26;
  border-color: #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
}

.dark .dashboard-tabs__btn {
  color: #8b95a5;
}

.dark .dashboard-tabs__btn:hover {
  color: #c9d1d9;
  background-color: #252a36;
}

.dark .dashboard-tabs__btn--active {
  background-color: var(--w-500);
  color: #fff;
}

.dark .dashboard-select {
  background-color: #252a36;
  border-color: #3d4455;
  color: var(--s-100);
}

.dark .dashboard-select:hover {
  border-color: #4d5566;
  background-color: #2d3343;
}

.dark .metric-card {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.dark .metric-card:hover {
  border-color: #3d4455;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.4);
}

.dark .metric-card__label {
  color: #8b95a5;
}

.dark .metric-card__sub {
  color: #6b7280;
}

.dark .card {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.dark .dashboard-loading {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
}

.dark .card__title {
  color: var(--s-100);
}

.dark .funnel-stage__name {
  color: #c9d1d9;
}

.dark .funnel-stage__bar-container,
.dark .loss-reason__bar-container {
  background-color: #252a36;
}

.dark .conversion-badge {
  background-color: #252a36;
  border: 1px solid #3d4455;
  color: #a5b4c5;
}

.dark .performer {
  background-color: #252a36;
  border: 1px solid #2d3343;
}

.dark .performer:hover {
  background-color: #2d3343;
  border-color: #3d4455;
}

.dark .performer__name {
  color: #e5e7eb;
}

.dark .performer__count {
  color: #8b95a5;
}

.dark .conversion {
  background-color: #252a36;
  border: 1px solid #2d3343;
}

.dark .conversion:hover {
  background-color: #2d3343;
  border-color: #3d4455;
}

.dark .conversion--total {
  background-color: rgba(59, 130, 246, 0.1);
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.dark .conversion__stage {
  color: #c9d1d9;
}

.dark .conversion__arrow {
  color: #6b7280;
}

.dark .empty-state {
  color: #6b7280;
}

.dark .loss-reason__name {
  color: #a5b4c5;
}

.dark .loss-reason__percent {
  color: #8b95a5;
}
</style>
