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

      <!-- Campos Personalizados -->
      <div v-if="customFields.length > 0" class="filter-item">
        <select v-model="selectedCustomField" class="filter-select" @change="onCustomFieldSelect">
          <option value="">🏷️ Campo personalizado</option>
          <option v-for="field in customFields" :key="field.field_key" :value="field.field_key">
            {{ field.name }}
          </option>
        </select>
      </div>

      <!-- Valor do Campo Personalizado -->
      <div v-if="selectedCustomField" class="filter-item filter-item--custom-value">
        <select
          v-if="selectedFieldType === 'select' || selectedFieldType === 'multiselect'"
          v-model="localFilters.custom_value"
          class="filter-select"
          @change="applyFilters"
        >
          <option value="">Todos</option>
          <option v-for="opt in selectedFieldOptions" :key="opt" :value="opt">
            {{ opt }}
          </option>
        </select>
        <select
          v-else-if="selectedFieldType === 'checkbox'"
          v-model="localFilters.custom_value"
          class="filter-select"
          @change="applyFilters"
        >
          <option value="">Todos</option>
          <option value="true">Sim</option>
          <option value="false">Não</option>
        </select>
        <!-- ✅ NOVO: Input de data formatado para campo created_at -->
        <div v-else-if="selectedCustomField === 'created_at'" class="date-filter-wrapper">
          <input
            v-model="formattedDate"
            type="text"
            placeholder="dd/mm/aaaa, mm/aaaa ou aaaa"
            class="filter-input"
            maxlength="10"
            @input="onDateInput"
            @blur="validateDate"
          />
          <span v-if="dateError" class="error-text">{{ dateError }}</span>
          <span v-else-if="dateHint" class="hint-text">{{ dateHint }}</span>
        </div>
        <input
          v-else
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
      sort_by: 'last_activity',
    });

    const selectedCustomField = ref('');
    
    // ✅ NOVO: Estados para formatação de data
    const formattedDate = ref('');
    const dateError = ref('');
    const dateHint = ref('');
    
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
        sort_by: 'last_activity',
      };
      selectedCustomField.value = '';
      formattedDate.value = '';
      dateError.value = '';
      dateHint.value = '';
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
      formattedDate.value = '';
      dateError.value = '';
      dateHint.value = '';
      applyFilters();
    };

    const onCustomFieldSelect = () => {
      localFilters.value.custom_value = '';
      localFilters.value.custom_field = selectedCustomField.value;
      formattedDate.value = '';
      dateError.value = '';
      dateHint.value = '';
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

    // ✅ NOVO: Formata data enquanto digita
    const onDateInput = (event) => {
      let value = event.target.value.replace(/[^\d\/]/g, '');
      value = value.replace(/\/+/g, '/');
      
      const numbers = value.replace(/\//g, '');
      const slashCount = (value.match(/\//g) || []).length;
      
      dateError.value = '';
      dateHint.value = '';
      
      // Apenas ano (aaaa)
      if (slashCount === 0 && numbers.length <= 4) {
        formattedDate.value = numbers;
        if (numbers.length === 4) {
          const year = parseInt(numbers);
          if (year >= 1900 && year <= 2100) {
            localFilters.value.custom_value = year.toString();
            dateHint.value = `Filtrando por ano: ${year}`;
            applyFilters();
          } else {
            dateError.value = 'Ano inválido';
          }
        } else {
          localFilters.value.custom_value = '';
        }
        return;
      }
      
      // Mês e ano (mm/aaaa)
      if (slashCount === 1) {
        const parts = value.split('/');
        const monthPart = parts[0].substring(0, 2);
        const yearPart = (parts[1] || '').substring(0, 4);
        
        formattedDate.value = monthPart + (yearPart ? '/' + yearPart : '');
        
        if (monthPart.length === 2 && yearPart.length === 4) {
          const month = parseInt(monthPart);
          const year = parseInt(yearPart);
          
          if (month >= 1 && month <= 12 && year >= 1900 && year <= 2100) {
            localFilters.value.custom_value = `${year}-${monthPart}`;
            dateHint.value = `Filtrando por mês: ${monthPart}/${year}`;
            applyFilters();
          } else {
            dateError.value = 'Mês ou ano inválido';
            localFilters.value.custom_value = '';
          }
        } else {
          localFilters.value.custom_value = '';
        }
        return;
      }
      
      // Data completa (dd/mm/aaaa)
      if (slashCount === 2 || numbers.length > 6) {
        const parts = value.split('/');
        const day = (parts[0] || '').substring(0, 2);
        const month = (parts[1] || '').substring(0, 2);
        const year = (parts[2] || '').substring(0, 4);
        
        let formatted = day;
        if (month) formatted += '/' + month;
        if (year) formatted += '/' + year;
        
        formattedDate.value = formatted;
        
        if (day.length === 2 && month.length === 2 && year.length === 4) {
          const d = parseInt(day);
          const m = parseInt(month);
          const y = parseInt(year);
          
          if (isValidDate(d, m, y)) {
            localFilters.value.custom_value = `${year}-${month}-${day}`;
            dateHint.value = `Filtrando por dia: ${formatted}`;
            applyFilters();
          } else {
            dateError.value = 'Data inválida';
            localFilters.value.custom_value = '';
          }
        } else {
          localFilters.value.custom_value = '';
        }
        return;
      }
      
      formattedDate.value = value;
      localFilters.value.custom_value = '';
    };

    // ✅ NOVO: Valida ao sair do campo
    const validateDate = () => {
      if (!formattedDate.value) return;
      
      const slashCount = (formattedDate.value.match(/\//g) || []).length;
      
      if (slashCount === 0 && formattedDate.value.length !== 4) {
        dateError.value = 'Ano deve ter 4 dígitos';
      } else if (slashCount === 1) {
        const parts = formattedDate.value.split('/');
        if (parts[0].length !== 2 || parts[1].length !== 4) {
          dateError.value = 'Formato: mm/aaaa';
        }
      } else if (slashCount === 2) {
        const parts = formattedDate.value.split('/');
        if (parts[0].length !== 2 || parts[1].length !== 2 || parts[2].length !== 4) {
          dateError.value = 'Formato: dd/mm/aaaa';
        }
      }
    };

    // ✅ NOVO: Valida se a data é real
    const isValidDate = (day, month, year) => {
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > 2100) return false;
      if (day < 1 || day > 31) return false;
      
      const daysInMonth = [
        31,
        ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0) ? 29 : 28,
        31, 30, 31, 30, 31, 31, 30, 31, 30, 31
      ];
      
      return day <= daysInMonth[month - 1];
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
      onCustomFieldSelect,
      getAssigneeName,
      getStatusLabel,
      getTasksFilterLabel,
      getCustomFieldName,
      formatValueRange,
      // ✅ NOVO: Exportar funções e refs de data
      formattedDate,
      dateError,
      dateHint,
      onDateInput,
      validateDate,
    };
  },
};
</script>

<style scoped>
.kanban-filters {
  padding: 12px 16px;
  background-color: rgb(var(--slate-2));
  border-bottom: 1px solid rgb(var(--slate-4));
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

.filter-item--custom-value {
  min-width: 200px;
}

.filter-item--sort {
  margin-left: auto;
}

.filter-input,
.filter-select {
  padding: 8px 12px;
  background-color: rgb(var(--slate-1));
  border: 1px solid rgb(var(--slate-4));
  border-radius: 6px;
  color: rgb(var(--slate-12));
  font-size: 13px;
}

.filter-input:focus,
.filter-select:focus {
  outline: none;
  border-color: rgb(var(--blue-9));
}

.filter-input::placeholder {
  color: rgb(var(--slate-9));
}

.filter-input--small {
  width: 80px;
}

.filter-prefix {
  color: rgb(var(--slate-10));
  font-size: 13px;
  margin-right: 4px;
}

.filter-separator {
  color: rgb(var(--slate-9));
  margin: 0 2px;
}

.filter-clear {
  padding: 8px 12px;
  background-color: rgb(var(--slate-4));
  border: none;
  border-radius: 6px;
  color: rgb(var(--slate-12));
  font-size: 13px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.filter-clear:hover {
  background-color: rgb(var(--slate-5));
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
  color: rgb(var(--slate-10));
}

.filter-tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 8px;
  background-color: rgb(var(--blue-9));
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

/* ✅ NOVO: Estilos para filtro de data */
.date-filter-wrapper {
  position: relative;
  width: 100%;
}

.error-text {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  color: rgb(var(--red-11));
  font-size: 12px;
  font-weight: 500;
}

.hint-text {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  color: rgb(var(--blue-11));
  font-size: 12px;
  font-weight: 500;
}
</style>
