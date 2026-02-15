<template>
  <div class="kanban-dashboard">
    <!-- Header -->
    <div class="dashboard-header">
      <h1 class="dashboard-header__title">📊 Dashboard de Vendas</h1>
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

    <!-- Loading -->
    <div v-if="isLoading" class="dashboard-loading">
      Carregando...
    </div>

    <template v-else-if="summary">
      <!-- Métricas principais -->
      <div class="metrics-grid">
        <div class="metric-card">
          <div class="metric-card__label">Total em Negociação</div>
          <div class="metric-card__value metric-card__value--blue">
            {{ formatCurrency(summary.totals.open_value) }}
          </div>
          <div class="metric-card__sub">{{ summary.totals.open_count }} negócios ativos</div>
        </div>
        <div class="metric-card">
          <div class="metric-card__label">Ganhos no Período</div>
          <div class="metric-card__value metric-card__value--green">
            {{ formatCurrency(summary.totals.won_value) }}
          </div>
          <div class="metric-card__sub">{{ summary.totals.won_count }} negócios fechados</div>
        </div>
        <div class="metric-card">
          <div class="metric-card__label">Perdidos no Período</div>
          <div class="metric-card__value metric-card__value--red">
            {{ formatCurrency(summary.totals.lost_value) }}
          </div>
          <div class="metric-card__sub">{{ summary.totals.lost_count }} negócios perdidos</div>
        </div>
        <div class="metric-card">
          <div class="metric-card__label">Taxa de Conversão</div>
          <div class="metric-card__value metric-card__value--yellow">
            {{ summary.totals.conversion_rate }}%
          </div>
          <div class="metric-card__sub">
            {{ summary.totals.won_count }} ganhos / {{ summary.totals.won_count + summary.totals.lost_count }} fechados
          </div>
        </div>
      </div>

      <!-- Grid principal -->
      <div class="main-grid">
        <!-- Funil de vendas -->
        <div class="card">
          <div class="card__title">🎯 Funil de Vendas</div>
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
                  {{ stage.count }}
                </div>
              </div>
              <div class="funnel-stage__values">
                <span class="funnel-stage__count">{{ stage.count }}</span>
                <span class="funnel-stage__value">{{ formatCurrency(stage.value) }}</span>
              </div>
              <div class="funnel-stage__conversion">
                <template v-if="index > 0 && summary.stage_conversions[index - 1]">
                  {{ summary.stage_conversions[index - 1].conversion_rate }}%
                </template>
              </div>
            </div>
          </div>
        </div>

        <!-- Motivos de perda -->
        <div class="card">
          <div class="card__title">❌ Motivos de Perda</div>
          <div v-if="lossReasons && lossReasons.reasons.length > 0" class="loss-reasons">
            <div v-for="reason in lossReasons.reasons" :key="reason.reason" class="loss-reason">
              <div class="loss-reason__name">{{ reason.reason }}</div>
              <div class="loss-reason__bar-container">
                <div class="loss-reason__bar" :style="{ width: reason.percentage + '%' }">
                  {{ reason.count }}
                </div>
              </div>
              <div class="loss-reason__percent">{{ reason.percentage }}%</div>
            </div>
          </div>
          <div v-else class="empty-state">Nenhuma perda registrada no período</div>
        </div>
      </div>

      <!-- Grid secundário -->
      <div class="secondary-grid">
        <!-- Top performers -->
        <div class="card">
          <div class="card__title">🏆 Top Vendedores</div>
          <div v-if="topPerformers && topPerformers.performers.length > 0" class="performers">
            <div v-for="(performer, index) in topPerformers.performers" :key="performer.id" class="performer">
              <div class="performer__rank" :class="`performer__rank--${index + 1}`">
                {{ index + 1 }}
              </div>
              <div class="performer__avatar">{{ getInitials(performer.name) }}</div>
              <div class="performer__info">
                <div class="performer__name">{{ performer.name }}</div>
                <div class="performer__count">{{ performer.won_count }} vendas fechadas</div>
              </div>
              <div class="performer__value">{{ formatCurrency(performer.total_value) }}</div>
            </div>
          </div>
          <div v-else class="empty-state">Nenhuma venda fechada no período</div>
        </div>

        <!-- Conversão entre estágios -->
        <div class="card">
          <div class="card__title">📈 Conversão entre Estágios</div>
          <div v-if="summary.stage_conversions.length > 0" class="conversions">
            <div v-for="conv in summary.stage_conversions" :key="conv.from_stage + conv.to_stage" class="conversion">
              <span>{{ conv.from_stage }}</span>
              <span class="conversion__arrow">→</span>
              <span>{{ conv.to_stage }}</span>
              <span class="conversion__rate" :class="getConversionClass(conv.conversion_rate)">
                {{ conv.conversion_rate }}%
              </span>
            </div>
            <div class="conversion conversion--total">
              <span><strong>Conversão Total</strong></span>
              <span class="conversion__arrow">→</span>
              <span>Lead → Venda</span>
              <span class="conversion__rate" :class="getConversionClass(summary.totals.conversion_rate)">
                {{ summary.totals.conversion_rate }}%
              </span>
            </div>
          </div>
          <div v-else class="empty-state">Dados insuficientes</div>
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

export default {
  name: 'KanbanDashboard',
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

    onMounted(() => {
      loadPipelines();
    });

    return {
      pipelines,
      selectedPipelineId,
      selectedPeriod,
      isLoading,
      summary,
      lossReasons,
      topPerformers,
      loadData,
      formatCurrency,
      getInitials,
      getBarWidth,
      getConversionClass,
    };
  },
};
</script>

<style scoped>
.kanban-dashboard {
  padding: 24px;
  background-color: #111827;
  min-height: 100vh;
  width: 100%;
  max-width: 100%;
  color: #f3f4f6;
  box-sizing: border-box;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.dashboard-header__title {
  font-size: 24px;
  font-weight: 600;
}

.dashboard-header__filters {
  display: flex;
  gap: 12px;
}

.dashboard-select {
  padding: 8px 12px;
  background-color: #1f2937;
  border: 1px solid #374151;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 14px;
  cursor: pointer;
}

.dashboard-loading {
  text-align: center;
  padding: 60px;
  color: #9ca3af;
  font-size: 16px;
}

.empty-state {
  text-align: center;
  padding: 24px;
  color: #6b7280;
  font-size: 14px;
}

/* Métricas */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
  width: 100%;
}

.metric-card {
  background-color: #1f2937;
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #374151;
}

.metric-card__label {
  font-size: 13px;
  color: #9ca3af;
  margin-bottom: 8px;
}

.metric-card__value {
  font-size: 24px;
  font-weight: 700;
}

.metric-card__value--green { color: #10b981; }
.metric-card__value--red { color: #ef4444; }
.metric-card__value--blue { color: #3b82f6; }
.metric-card__value--yellow { color: #f59e0b; }

.metric-card__sub {
  font-size: 12px;
  color: #6b7280;
  margin-top: 4px;
}

/* Grids */
.main-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 24px;
  margin-bottom: 24px;
  width: 100%;
}

.secondary-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  width: 100%;
}

.card {
  background-color: #1f2937;
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #374151;
  min-width: 0;
}

.card__title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 20px;
}

/* Funil */
.funnel {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.funnel-stage {
  display: flex;
  align-items: center;
  gap: 12px;
}

.funnel-stage__color {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.funnel-stage__name {
  width: 100px;
  font-size: 14px;
  flex-shrink: 0;
}

.funnel-stage__bar-container {
  flex: 1;
  height: 32px;
  background-color: #111827;
  border-radius: 4px;
  overflow: hidden;
  min-width: 80px;
}

.funnel-stage__bar {
  height: 100%;
  border-radius: 4px;
  display: flex;
  align-items: center;
  padding-left: 12px;
  font-size: 13px;
  font-weight: 500;
}

.funnel-stage__values {
  width: 120px;
  text-align: right;
  font-size: 13px;
  flex-shrink: 0;
}

.funnel-stage__count {
  color: #f3f4f6;
}

.funnel-stage__value {
  color: #10b981;
  margin-left: 8px;
}

.funnel-stage__conversion {
  width: 50px;
  text-align: center;
  font-size: 12px;
  color: #9ca3af;
  flex-shrink: 0;
}

/* Motivos de perda */
.loss-reasons {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.loss-reason {
  display: flex;
  align-items: center;
  gap: 12px;
}

.loss-reason__name {
  width: 100px;
  font-size: 13px;
  color: #d1d5db;
  flex-shrink: 0;
}

.loss-reason__bar-container {
  flex: 1;
  height: 24px;
  background-color: #111827;
  border-radius: 4px;
  overflow: hidden;
  min-width: 40px;
}

.loss-reason__bar {
  height: 100%;
  background-color: #ef4444;
  border-radius: 4px;
  display: flex;
  align-items: center;
  padding-left: 8px;
  font-size: 12px;
}

.loss-reason__percent {
  width: 50px;
  text-align: right;
  font-size: 13px;
  color: #9ca3af;
  flex-shrink: 0;
}

/* Performers */
.performers {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.performer {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background-color: #111827;
  border-radius: 8px;
}

.performer__rank {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background-color: #374151;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  flex-shrink: 0;
}

.performer__rank--1 { background-color: #f59e0b; color: #111827; }
.performer__rank--2 { background-color: #9ca3af; color: #111827; }
.performer__rank--3 { background-color: #b45309; color: #fff; }

.performer__avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background-color: #3b82f6;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  flex-shrink: 0;
}

.performer__info {
  flex: 1;
  min-width: 0;
}

.performer__name {
  font-size: 14px;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.performer__count {
  font-size: 12px;
  color: #9ca3af;
}

.performer__value {
  font-size: 14px;
  font-weight: 600;
  color: #10b981;
  flex-shrink: 0;
}

/* Conversões */
.conversions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.conversion {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.conversion--total {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #374151;
}

.conversion__arrow {
  color: #6b7280;
}

.conversion__rate {
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 500;
  font-size: 12px;
  margin-left: auto;
}

.conversion__rate--high { background-color: #065f46; color: #10b981; }
.conversion__rate--medium { background-color: #92400e; color: #f59e0b; }
.conversion__rate--low { background-color: #991b1b; color: #ef4444; }

/* Responsivo */
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
  .metrics-grid {
    grid-template-columns: 1fr 1fr;
  }
  .metric-card__value {
    font-size: 20px;
  }
}

@media (max-width: 480px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}
</style>
