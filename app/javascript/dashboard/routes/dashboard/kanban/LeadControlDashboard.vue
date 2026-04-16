<template>
  <div class="lead-dashboard">
    <!-- Loading -->
    <div v-if="isLoading" class="lead-loading">
      <div class="lead-loading__spinner"></div>
      <span>Carregando dados de leads...</span>
    </div>

    <template v-else-if="report">
      <!-- Source Breakdown Table -->
      <div class="lead-card">
        <div class="lead-card__title">
          <svg class="lead-card__title-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
          Leads por Origem
        </div>
        <div class="lead-table-wrapper">
          <table class="lead-table">
            <thead>
              <tr>
                <th>Origem</th>
                <th class="lead-table__num">Contatados</th>
                <th class="lead-table__num">Responderam</th>
                <th class="lead-table__num">Calls</th>
                <th class="lead-table__num">Vendas</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="source in report.sources" :key="source.source">
                <td>
                  <div class="lead-table__source">
                    <span class="lead-table__source-dot" :style="{ backgroundColor: sourceColor(source.source) }"></span>
                    {{ source.source }}
                  </div>
                </td>
                <td class="lead-table__num">{{ source.contacted }}</td>
                <td class="lead-table__num">{{ source.responded }}</td>
                <td class="lead-table__num">{{ source.calls }}</td>
                <td class="lead-table__num">
                  <span class="lead-table__sales-badge" v-if="source.sales > 0">{{ source.sales }}</span>
                  <span v-else class="lead-table__zero">0</span>
                </td>
              </tr>
            </tbody>
            <tfoot>
              <tr>
                <td><strong>Total</strong></td>
                <td class="lead-table__num"><strong>{{ report.totals.total_contacted }}</strong></td>
                <td class="lead-table__num"><strong>{{ report.totals.total_responded }}</strong></td>
                <td class="lead-table__num"><strong>{{ report.totals.total_calls }}</strong></td>
                <td class="lead-table__num">
                  <strong>{{ report.totals.total_new_sales + report.totals.total_renewals }}</strong>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- Totals Cards -->
      <div class="lead-totals-grid">
        <div class="lead-total-card">
          <div class="lead-total-card__icon lead-total-card__icon--blue">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <line x1="19" y1="8" x2="19" y2="14"/><line x1="22" y1="11" x2="16" y2="11"/>
            </svg>
          </div>
          <div class="lead-total-card__content">
            <div class="lead-total-card__label">Total Leads Contatados</div>
            <div class="lead-total-card__value lead-total-card__value--blue">
              {{ report.totals.total_contacted }}
            </div>
          </div>
        </div>

        <div class="lead-total-card">
          <div class="lead-total-card__icon lead-total-card__icon--cyan">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
          </div>
          <div class="lead-total-card__content">
            <div class="lead-total-card__label">Total que Responderam</div>
            <div class="lead-total-card__value lead-total-card__value--cyan">
              {{ report.totals.total_responded }}
            </div>
          </div>
        </div>

        <div class="lead-total-card">
          <div class="lead-total-card__icon lead-total-card__icon--purple">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
            </svg>
          </div>
          <div class="lead-total-card__content">
            <div class="lead-total-card__label">Total Calls</div>
            <div class="lead-total-card__value lead-total-card__value--purple">
              {{ report.totals.total_calls }}
            </div>
          </div>
        </div>

        <div class="lead-total-card">
          <div class="lead-total-card__icon lead-total-card__icon--green">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <div class="lead-total-card__content">
            <div class="lead-total-card__label">Total Novas Vendas</div>
            <div class="lead-total-card__value lead-total-card__value--green">
              {{ report.totals.total_new_sales }}
            </div>
          </div>
        </div>

        <div class="lead-total-card">
          <div class="lead-total-card__icon lead-total-card__icon--orange">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
            </svg>
          </div>
          <div class="lead-total-card__content">
            <div class="lead-total-card__label">Total Renovações</div>
            <div class="lead-total-card__value lead-total-card__value--orange">
              {{ report.totals.total_renewals }}
            </div>
          </div>
        </div>
      </div>

      <!-- Revenue Cards -->
      <div class="lead-card">
        <div class="lead-card__title">
          <svg class="lead-card__title-icon lead-card__title-icon--green" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
          </svg>
          Faturamento
        </div>
        <div class="lead-revenue-grid">
          <div class="lead-revenue-item">
            <div class="lead-revenue-item__label">Faturamento Novas Vendas</div>
            <div class="lead-revenue-item__value lead-revenue-item__value--green">
              {{ formatCurrency(report.totals.revenue_new_sales) }}
            </div>
          </div>
          <div class="lead-revenue-item">
            <div class="lead-revenue-item__label">Faturamento Renovações</div>
            <div class="lead-revenue-item__value lead-revenue-item__value--orange">
              {{ formatCurrency(report.totals.revenue_renewals) }}
            </div>
          </div>
          <div class="lead-revenue-item lead-revenue-item--total">
            <div class="lead-revenue-item__label">Faturamento Total Mês</div>
            <div class="lead-revenue-item__value lead-revenue-item__value--total">
              {{ formatCurrency(report.totals.revenue_total) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Conversion Rates -->
      <div class="lead-card">
        <div class="lead-card__title">
          <svg class="lead-card__title-icon lead-card__title-icon--yellow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/>
          </svg>
          Taxas de Conversão
        </div>
        <div class="lead-conversions-grid">
          <div class="lead-conversion-card">
            <div class="lead-conversion-card__flow">
              <span class="lead-conversion-card__stage">Atendimento</span>
              <svg class="lead-conversion-card__arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
              </svg>
              <span class="lead-conversion-card__stage">Call</span>
            </div>
            <div class="lead-conversion-card__rate" :class="conversionClass(report.totals.conversion_contact_to_call)">
              {{ report.totals.conversion_contact_to_call }}%
            </div>
            <div class="lead-conversion-card__detail">
              {{ report.totals.total_calls }} calls / {{ report.totals.total_contacted }} leads
            </div>
          </div>
          <div class="lead-conversion-card">
            <div class="lead-conversion-card__flow">
              <span class="lead-conversion-card__stage">Call</span>
              <svg class="lead-conversion-card__arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
              </svg>
              <span class="lead-conversion-card__stage">Venda</span>
            </div>
            <div class="lead-conversion-card__rate" :class="conversionClass(report.totals.conversion_call_to_sale)">
              {{ report.totals.conversion_call_to_sale }}%
            </div>
            <div class="lead-conversion-card__detail">
              {{ report.totals.total_new_sales + report.totals.total_renewals }} vendas / {{ report.totals.total_calls }} calls
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Empty state -->
    <div v-else class="lead-empty">
      <svg class="lead-empty__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <line x1="17" y1="11" x2="23" y2="11"/>
      </svg>
      <span>Nenhum dado de leads encontrado para o período selecionado</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LeadControlDashboard',
  props: {
    report: {
      type: Object,
      default: null,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
  setup(props) {
    const SOURCE_COLORS = {
      LinkedIn: '#0077B5',
      Instagram: '#E4405F',
      Jetsales: '#6366f1',
      'Tráfego Pago': '#f59e0b',
      'Lançamento': '#8b5cf6',
      Passivo: '#6b7280',
    };

    const sourceColor = (source) => SOURCE_COLORS[source] || '#94a3b8';

    const formatCurrency = (value) => {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      }).format(value || 0);
    };

    const conversionClass = (rate) => {
      if (rate >= 40) return 'lead-conversion-card__rate--high';
      if (rate >= 20) return 'lead-conversion-card__rate--medium';
      return 'lead-conversion-card__rate--low';
    };

    return {
      sourceColor,
      formatCurrency,
      conversionClass,
    };
  },
};
</script>

<style scoped>
/* ===== BASE ===== */
.lead-dashboard {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* ===== LOADING ===== */
.lead-loading {
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

.lead-loading__spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--s-200);
  border-top-color: var(--w-500);
  border-radius: 50%;
  animation: lead-spin 1s linear infinite;
}

@keyframes lead-spin {
  to { transform: rotate(360deg); }
}

/* ===== EMPTY ===== */
.lead-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
  color: var(--s-400);
  font-size: 14px;
  gap: 12px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
}

.lead-empty__icon {
  width: 40px;
  height: 40px;
  opacity: 0.5;
}

/* ===== CARD ===== */
.lead-card {
  padding: 24px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.lead-card__title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 20px;
  color: var(--s-800);
}

.lead-card__title-icon {
  width: 22px;
  height: 22px;
  color: var(--w-500);
}

.lead-card__title-icon--green { color: #10b981; }
.lead-card__title-icon--yellow { color: #f59e0b; }

/* ===== TABLE ===== */
.lead-table-wrapper {
  overflow-x: auto;
}

.lead-table {
  width: 100%;
  border-collapse: collapse;
}

.lead-table th {
  padding: 12px 16px;
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--s-500);
  border-bottom: 2px solid var(--s-100);
}

.lead-table td {
  padding: 14px 16px;
  font-size: 14px;
  color: var(--s-700);
  border-bottom: 1px solid var(--s-75, var(--s-100));
}

.lead-table tbody tr {
  transition: background-color 0.15s ease;
}

.lead-table tbody tr:hover {
  background-color: var(--s-50);
}

.lead-table tfoot td {
  padding: 14px 16px;
  font-size: 14px;
  color: var(--s-800);
  border-top: 2px solid var(--s-200);
  border-bottom: none;
  background-color: var(--s-50);
}

.lead-table__num {
  text-align: center !important;
}

.lead-table__source {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 500;
}

.lead-table__source-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.lead-table__sales-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 26px;
  height: 26px;
  padding: 0 8px;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: #fff;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
}

.lead-table__zero {
  color: var(--s-400);
}

/* ===== TOTALS GRID ===== */
.lead-totals-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 16px;
}

.lead-total-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px;
  background-color: var(--white);
  border-radius: 16px;
  border: 1px solid var(--s-100);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
}

.lead-total-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.lead-total-card__icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.lead-total-card__icon svg {
  width: 24px;
  height: 24px;
  color: white;
}

.lead-total-card__icon--blue { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); }
.lead-total-card__icon--cyan { background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%); }
.lead-total-card__icon--purple { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); }
.lead-total-card__icon--green { background: linear-gradient(135deg, #10b981 0%, #059669 100%); }
.lead-total-card__icon--orange { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); }

.lead-total-card__content {
  flex: 1;
  min-width: 0;
}

.lead-total-card__label {
  font-size: 11px;
  color: var(--s-500);
  margin-bottom: 4px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 500;
}

.lead-total-card__value {
  font-size: 22px;
  font-weight: 700;
  line-height: 1.2;
}

.lead-total-card__value--blue { color: #3b82f6; }
.lead-total-card__value--cyan { color: #06b6d4; }
.lead-total-card__value--purple { color: #8b5cf6; }
.lead-total-card__value--green { color: #10b981; }
.lead-total-card__value--orange { color: #f59e0b; }

/* ===== REVENUE ===== */
.lead-revenue-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
}

.lead-revenue-item {
  padding: 20px;
  background-color: var(--s-50);
  border-radius: 12px;
  text-align: center;
  transition: background-color 0.15s ease;
}

.lead-revenue-item:hover {
  background-color: var(--s-100);
}

.lead-revenue-item--total {
  background-color: rgba(59, 130, 246, 0.08);
  border: 1px solid rgba(59, 130, 246, 0.15);
}

.lead-revenue-item--total:hover {
  background-color: rgba(59, 130, 246, 0.12);
}

.lead-revenue-item__label {
  font-size: 12px;
  color: var(--s-500);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 500;
}

.lead-revenue-item__value {
  font-size: 24px;
  font-weight: 700;
}

.lead-revenue-item__value--green { color: #10b981; }
.lead-revenue-item__value--orange { color: #f59e0b; }
.lead-revenue-item__value--total { color: #3b82f6; font-size: 28px; }

/* ===== CONVERSIONS ===== */
.lead-conversions-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.lead-conversion-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 24px;
  background-color: var(--s-50);
  border-radius: 12px;
  text-align: center;
  transition: background-color 0.15s ease;
}

.lead-conversion-card:hover {
  background-color: var(--s-100);
}

.lead-conversion-card__flow {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.lead-conversion-card__stage {
  font-weight: 600;
  color: var(--s-700);
}

.lead-conversion-card__arrow {
  width: 20px;
  height: 20px;
  color: var(--s-400);
}

.lead-conversion-card__rate {
  font-size: 32px;
  font-weight: 700;
  padding: 4px 20px;
  border-radius: 12px;
}

.lead-conversion-card__rate--high {
  color: #059669;
  background-color: rgba(16, 185, 129, 0.12);
}

.lead-conversion-card__rate--medium {
  color: #d97706;
  background-color: rgba(245, 158, 11, 0.12);
}

.lead-conversion-card__rate--low {
  color: #dc2626;
  background-color: rgba(239, 68, 68, 0.12);
}

.lead-conversion-card__detail {
  font-size: 12px;
  color: var(--s-500);
}

/* ===== RESPONSIVE ===== */
@media (max-width: 1200px) {
  .lead-totals-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  .lead-revenue-grid {
    grid-template-columns: 1fr;
  }
  .lead-conversions-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .lead-totals-grid {
    grid-template-columns: 1fr;
  }
  .lead-revenue-item__value {
    font-size: 20px;
  }
  .lead-revenue-item__value--total {
    font-size: 22px;
  }
  .lead-conversion-card__rate {
    font-size: 24px;
  }
}

/* ===== DARK MODE ===== */
.dark .lead-loading {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  color: #8b95a5;
}

.dark .lead-empty {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  color: #6b7280;
}

.dark .lead-card {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.dark .lead-card__title {
  color: var(--s-100);
}

.dark .lead-table th {
  color: #8b95a5;
  border-bottom-color: #2d3343;
}

.dark .lead-table td {
  color: #c9d1d9;
  border-bottom-color: #252a36;
}

.dark .lead-table tbody tr:hover {
  background-color: #252a36;
}

.dark .lead-table tfoot td {
  color: #e5e7eb;
  border-top-color: #3d4455;
  background-color: #252a36;
}

.dark .lead-total-card {
  background-color: #1a1d26;
  border: 1px solid #2d3343;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.dark .lead-total-card:hover {
  border-color: #3d4455;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.4);
}

.dark .lead-total-card__label {
  color: #8b95a5;
}

.dark .lead-revenue-item {
  background-color: #252a36;
}

.dark .lead-revenue-item:hover {
  background-color: #2d3343;
}

.dark .lead-revenue-item--total {
  background-color: rgba(59, 130, 246, 0.1);
  border-color: rgba(59, 130, 246, 0.3);
}

.dark .lead-revenue-item__label {
  color: #8b95a5;
}

.dark .lead-conversion-card {
  background-color: #252a36;
}

.dark .lead-conversion-card:hover {
  background-color: #2d3343;
}

.dark .lead-conversion-card__stage {
  color: #c9d1d9;
}

.dark .lead-conversion-card__arrow {
  color: #6b7280;
}

.dark .lead-conversion-card__detail {
  color: #6b7280;
}
</style>
