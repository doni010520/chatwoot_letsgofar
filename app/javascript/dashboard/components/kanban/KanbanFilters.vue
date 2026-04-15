<template>
  <div class="kanban-filters">
    <div class="filters-row">
      <!-- Busca -->
      <div class="filter-item filter-item--search">
        <input
          v-model="localFilters.search"
          type="text"
          placeholder="🔍 Buscar contato..."
          class="filter-input"
          @input="debouncedApply"
        />
      </div>

      <!-- Vendedor -->
      <div class="filter-item">
        <select v-model="localFilters.assignee_id" class="filter-select" @change="applyFilters">
          <option value="">👤 Todos os vendedores</option>
          <option v-for="user in assignees" :key="user.id" :value="user.id">
            {{ user.name }}
          </option>
        </select>
      </div>

      <!-- Status -->
      <div class="filter-item">
        <select v-model="localFilters.deal_status" class="filter-select" @change="applyFilters">
          <option value="">📊 Todos os status</option>
          <option value="open">🔵 Em aberto</option>
          <option value="won">🟢 Ganhos</option>
          <option value="lost">🔴 Perdidos</option>
        </select>
      </div>

      <!-- Tarefas -->
      <div class="filter-item">
        <select v-model="localFilters.tasks_filter" class="filter-select" @change="applyFilters">
          <option value="">📋 Todas as tarefas</option>
          <option value="with_tasks">Com tarefas pendentes</option>
          <option value="overdue">⚠️ Com tarefas atrasadas</option>
          <option value="due_today">📅 Vencendo hoje</option>
          <option value="no_tasks">Sem tarefas</option>
        </select>
      </div>

      <!-- Valor Mínimo/Máximo -->
      <div class="filter-item filter-item--value">
        <span class="filter-prefix">R$</span>
        <input
          v-model="localFilters.min_value"
          type="number"
          placeholder="Mín"
          class="filter-input filter-input--small"
          @input="debouncedApply"
        />
        <span class="filter-separator">-</span>
        <input
          v-model="localFilters.max_value"
          type="number"
          placeholder="Máx"
          class="filter-input filter-input--small"
          @input="debouncedApply"
        />
      </div>

      <!-- Filtro de Data de Entrada (Período) -->
      <div class="filter-item filter-item--date-range">
        <span class="filter-prefix">📅</span>
        <input
          v-model="dateFromInput"
          type="text"
          placeholder="De (dd/mm/aaaa)"
          class="filter-input filter-input--date"
          maxlength="10"
          @input="formatDateFromInput"
        />
        <span class="filter-separator">-</span>
        <input
          v-model="dateToInput"
          type="text"
          placeholder="Até (dd/mm/aaaa)"
          class="filter-input filter-input--date"
          maxlength="10"
          @input="formatDateToInput"
        />
      </div>

      <!-- Campos Personalizados -->
      <div v-if="customFields.length > 0" class="filter-item">
        <select v-model="selectedCustomField" class="filter-select" @change="onCustomFieldSelect">
          <option value="">🏷️ Campo personalizado</option>
          <option v-for="field in customFields" :key="field.field_key" :value="field.field_key">
            {{ field.name }}
          </option>
        </select>
      </div>
      
      <div v-if="selectedCustomField" class="filter-item">
        <input
          v-model="localFilters.custom_value"
          type="text"
          placeholder="Valor..."
          class="filter-input"
          @input="debouncedApply"
        />
      </div>

      <!-- Ordenação -->
      <div class="filter-item filter-item--sort">
        <select v-model="localFilters.sort_by" class="filter-select" @change="applyFilters">
          <option value="last_activity">🕐 Última atividade</option>
          <option value="value_desc">💰 Maior valor</option>
          <option value="value_asc">💰 Menor valor</option>
          <option value="newest">📅 Mais recentes</option>
          <option value="oldest">📅 Mais antigos</option>
        </select>
      </div>

      <!-- Limpar Filtros -->
      <button
        v-if="hasActiveFilters"
        class="filter-clear"
        @click="clearFilters"
      >
        ✕ Limpar
      </button>
    </div>

    <!-- Indicador de filtros ativos -->
    <div v-if="hasActiveFilters" class="filters-active">
      <span class="filters-active__label">Filtros ativos:</span>
      <span v-if="localFilters.search" class="filter-tag">
        Busca: "{{ localFilters.search }}"
        <button @click="removeFilter('search')">×</button>
      </span>
      <span v-if="localFilters.assignee_id" class="filter-tag">
        Vendedor: {{ getAssigneeName(localFilters.assignee_id) }}
        <button @click="removeFilter('assignee_id')">×</button>
      </span>
      <span v-if="localFilters.deal_status" class="filter-tag">
        Status: {{ getStatusLabel(localFilters.deal_status) }}
        <button @click="removeFilter('deal_status')">×</button>
      </span>
      <span v-if="localFilters.tasks_filter" class="filter-tag">
        Tarefas: {{ getTasksFilterLabel(localFilters.tasks_filter) }}
        <button @click="removeFilter('tasks_filter')">×</button>
      </span>
      <span v-if="localFilters.min_value || localFilters.max_value" class="filter-tag">
        Valor: {{ formatValueRange() }}
        <button @click="removeValueFilters">×</button>
      </span>
      <span v-if="localFilters.date_from || localFilters.date_to" class="filter-tag">
        Período: {{ formatDateRange() }}
        <button @click="removeDateFilters">×</button>
      </span>
      <span v-if="selectedCustomField && localFilters.custom_value" class="filter-tag">
        {{ getCustomFieldName() }}: {{ localFilters.custom_value }}
        <button @click="removeCustomFilter">×</button>
      </span>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue';

export default {
  name: 'KanbanFilters',
  props: {
    assignees: {
      type: Array,
      default: () => [],
    },
    customFields: {
      type: Array,
      default: () => [],
    },
    filters: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['filter-change'],
  setup(props, { emit }) {
    const localFilters = ref({
      search: '',
      assignee_id: '',
      deal_status: '',
      tasks_filter: '',
      min_value: '',
      max_value: '',
      custom_field: '',
      custom_value: '',
      date_from: '',
      date_to: '',
      sort_by: 'last_activity',
    });

    const dateFromInput = ref('');
    const dateToInput = ref('');

    const autoFormatDate = (raw) => {
      let digits = raw.replace(/\D/g, '');
      if (digits.length >= 2) digits = digits.substring(0, 2) + '/' + digits.substring(2);
      if (digits.length >= 5) digits = digits.substring(0, 5) + '/' + digits.substring(5, 9);
      return digits;
    };

    const ddmmyyyyToISO = (formatted) => {
      if (formatted.length !== 10) return '';
      const [day, month, year] = formatted.split('/');
      return `${year}-${month}-${day}`;
    };

    const formatDateFromInput = (event) => {
      dateFromInput.value = autoFormatDate(event.target.value);
      if (dateFromInput.value.length === 10) {
        localFilters.value.date_from = ddmmyyyyToISO(dateFromInput.value);
        applyFilters();
      } else if (dateFromInput.value.length === 0) {
        localFilters.value.date_from = '';
        applyFilters();
      }
    };

    const formatDateToInput = (event) => {
      dateToInput.value = autoFormatDate(event.target.value);
      if (dateToInput.value.length === 10) {
        localFilters.value.date_to = ddmmyyyyToISO(dateToInput.value);
        applyFilters();
      } else if (dateToInput.value.length === 0) {
        localFilters.value.date_to = '';
        applyFilters();
      }
    };

    const formatDateRange = () => {
      const from = dateFromInput.value;
      const to = dateToInput.value;
      if (from && to) return `${from} - ${to}`;
      if (from) return `a partir de ${from}`;
      if (to) return `até ${to}`;
      return '';
    };

    const removeDateFilters = () => {
      dateFromInput.value = '';
      dateToInput.value = '';
      localFilters.value.date_from = '';
      localFilters.value.date_to = '';
      applyFilters();
    };

    const selectedCustomField = ref('');
    let debounceTimer = null;

    const selectedFieldType = computed(() => {
      if (!selectedCustomField.value) return null;
      const field = props.customFields.find(f => f.field_key === selectedCustomField.value);
      return field?.field_type;
    });

    const selectedFieldOptions = computed(() => {
      if (!selectedCustomField.value) return [];
      const field = props.customFields.find(f => f.field_key === selectedCustomField.value);
      return field?.select_options || [];
    });

    const hasActiveFilters = computed(() => {
      return localFilters.value.search ||
        localFilters.value.assignee_id ||
        localFilters.value.deal_status ||
        localFilters.value.tasks_filter ||
        localFilters.value.min_value ||
        localFilters.value.max_value ||
        localFilters.value.date_from ||
        localFilters.value.date_to ||
        (selectedCustomField.value && localFilters.value.custom_value);
    });

    const applyFilters = () => {
      const filters = { ...localFilters.value };

      if (selectedCustomField.value && filters.custom_value) {
        filters.custom_field = selectedCustomField.value;
      } else {
        delete filters.custom_field;
        delete filters.custom_value;
      }

      // Manter sort_by mesmo se vazio
      const sortBy = filters.sort_by || 'last_activity';

      Object.keys(filters).forEach(key => {
        if (!filters[key] && key !== 'sort_by') delete filters[key];
      });

      filters.sort_by = sortBy;

      emit('filter-change', filters);
    };

    const debouncedApply = () => {
      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(applyFilters, 400);
    };

    const clearFilters = () => {
      localFilters.value = {
        search: '',
        assignee_id: '',
        deal_status: '',
        tasks_filter: '',
        min_value: '',
        max_value: '',
        custom_field: '',
        custom_value: '',
        date_from: '',
        date_to: '',
        sort_by: 'last_activity',
      };
      selectedCustomField.value = '';
      dateFromInput.value = '';
      dateToInput.value = '';
      applyFilters();
    };

    const removeFilter = (key) => {
      localFilters.value[key] = '';
      applyFilters();
    };

    const removeValueFilters = () => {
      localFilters.value.min_value = '';
      localFilters.value.max_value = '';
      applyFilters();
    };

    const removeCustomFilter = () => {
      selectedCustomField.value = '';
      localFilters.value.custom_field = '';
      localFilters.value.custom_value = '';
      applyFilters();
    };

    const onCustomFieldSelect = () => {
      localFilters.value.custom_value = '';
      localFilters.value.custom_field = selectedCustomField.value;
    };

    const getAssigneeName = (id) => {
      const user = props.assignees.find(u => u.id === parseInt(id));
      return user?.name || id;
    };

    const getStatusLabel = (status) => {
      const labels = { open: 'Em aberto', won: 'Ganhos', lost: 'Perdidos' };
      return labels[status] || status;
    };

    const getTasksFilterLabel = (filter) => {
      const labels = {
        with_tasks: 'Com pendentes',
        overdue: 'Atrasadas',
        due_today: 'Vencendo hoje',
        no_tasks: 'Sem tarefas'
      };
      return labels[filter] || filter;
    };

    const getCustomFieldName = () => {
      const field = props.customFields.find(f => f.field_key === selectedCustomField.value);
      return field?.name || selectedCustomField.value;
    };

    const formatValueRange = () => {
      const min = localFilters.value.min_value;
      const max = localFilters.value.max_value;
      if (min && max) return `R$ ${min} - R$ ${max}`;
      if (min) return `>= R$ ${min}`;
      if (max) return `<= R$ ${max}`;
      return '';
    };

    watch(() => props.filters, (newFilters) => {
      if (newFilters) {
        Object.assign(localFilters.value, newFilters);
        if (newFilters.custom_field) {
          selectedCustomField.value = newFilters.custom_field;
        }
      }
    }, { immediate: true });

    return {
      localFilters,
      selectedCustomField,
      selectedFieldType,
      selectedFieldOptions,
      hasActiveFilters,
      applyFilters,
      debouncedApply,
      clearFilters,
      removeFilter,
      removeValueFilters,
      removeCustomFilter,
      removeDateFilters,
      onCustomFieldSelect,
      getAssigneeName,
      getStatusLabel,
      getTasksFilterLabel,
      getCustomFieldName,
      formatValueRange,
      formatDateRange,
      dateFromInput,
      dateToInput,
      formatDateFromInput,
      formatDateToInput,
    };
  },
};
</script>

<style scoped>
.kanban-filters {
  padding: 12px 16px;
  background-color: #1f2937;
  border-bottom: 1px solid #374151;
}

.filters-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.filter-item {
  display: flex;
  align-items: center;
}

.filter-item--search {
  flex: 1;
  min-width: 200px;
  max-width: 300px;
}

.filter-item--value {
  display: flex;
  align-items: center;
  gap: 4px;
}

.filter-item--date-range {
  display: flex;
  align-items: center;
  gap: 4px;
}

.filter-input--date {
  width: 130px;
}

.filter-item--sort {
  margin-left: auto;
}

.filter-input,
.filter-select {
  padding: 8px 12px;
  background-color: #111827;
  border: 1px solid #374151;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 13px;
}

.filter-input:focus,
.filter-select:focus {
  outline: none;
  border-color: #3b82f6;
}

.filter-input::placeholder {
  color: #6b7280;
}

.filter-input--small {
  width: 80px;
}

.filter-prefix {
  color: #9ca3af;
  font-size: 13px;
  margin-right: 4px;
}

.filter-separator {
  color: #6b7280;
  margin: 0 2px;
}

.filter-clear {
  padding: 8px 12px;
  background-color: #374151;
  border: none;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 13px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.filter-clear:hover {
  background-color: #4b5563;
}

.filters-active {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
  flex-wrap: wrap;
}

.filters-active__label {
  font-size: 12px;
  color: #9ca3af;
}

.filter-tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 8px;
  background-color: #3b82f6;
  border-radius: 4px;
  font-size: 12px;
  color: white;
}

.filter-tag button {
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  padding: 0;
  font-size: 14px;
  line-height: 1;
  opacity: 0.8;
}

.filter-tag button:hover {
  opacity: 1;
}
</style>
