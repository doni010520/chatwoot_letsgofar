<template>
  <div class="automations-manager">
    <!-- Header -->
    <div class="automations-header">
      <div class="automations-header__left">
        <h2 class="automations-header__title">
          <svg class="automations-header__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 3v3m0 12v3m-9-9h3m12 0h3M5.6 5.6l2.1 2.1m8.6 8.6 2.1 2.1m0-12.8-2.1 2.1m-8.6 8.6-2.1 2.1"/>
          </svg>
          Automações
        </h2>
        <span class="automations-header__count">{{ automations.length }} automações</span>
      </div>
      <button class="btn-primary" @click="openCreateModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        Nova Automação
      </button>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="automations-loading">
      <div class="loading-spinner"></div>
      <span>Carregando automações...</span>
    </div>

    <!-- Empty State -->
    <div v-else-if="automations.length === 0" class="automations-empty">
      <svg class="automations-empty__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
      </svg>
      <h3>Nenhuma automação configurada</h3>
      <p>Crie automações para executar ações automaticamente quando eventos acontecerem.</p>
      <button class="btn-primary" @click="openCreateModal">Criar Primeira Automação</button>
    </div>

    <!-- Lista de Automações -->
    <div v-else class="automations-list">
      <div
        v-for="automation in automations"
        :key="automation.id"
        class="automation-card"
        :class="{ 'automation-card--inactive': !automation.is_active }"
      >
        <div class="automation-card__header">
          <div class="automation-card__info">
            <h3 class="automation-card__name">{{ automation.name }}</h3>
            <span class="automation-card__trigger" :class="`trigger--${automation.trigger_type}`">
              {{ automation.trigger_info.name }}
            </span>
          </div>
          <div class="automation-card__actions">
            <button
              class="btn-icon"
              :class="automation.is_active ? 'btn-icon--success' : 'btn-icon--muted'"
              @click="toggleActive(automation)"
              :title="automation.is_active ? 'Desativar' : 'Ativar'"
            >
              <svg v-if="automation.is_active" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14"/><circle cx="19" cy="12" r="3"/>
              </svg>
              <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14"/><circle cx="5" cy="12" r="3"/>
              </svg>
            </button>
            <button class="btn-icon" @click="openEditModal(automation)" title="Editar">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
              </svg>
            </button>
            <button class="btn-icon btn-icon--danger" @click="confirmDelete(automation)" title="Excluir">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
              </svg>
            </button>
          </div>
        </div>

        <p v-if="automation.description" class="automation-card__description">
          {{ automation.description }}
        </p>

        <div class="automation-card__details">
          <div class="automation-card__conditions" v-if="automation.conditions.length">
            <span class="detail-label">Condições:</span>
            <span class="detail-value">{{ automation.conditions.length }} condição(ões)</span>
          </div>
          <div class="automation-card__actions-count">
            <span class="detail-label">Ações:</span>
            <span class="detail-value">{{ automation.actions.length }} ação(ões)</span>
          </div>
        </div>

        <div class="automation-card__stats">
          <span class="stat">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
            </svg>
            {{ automation.executions_count }} execuções
          </span>
          <span v-if="automation.last_executed_at" class="stat">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
            </svg>
            {{ formatDate(automation.last_executed_at) }}
          </span>
        </div>

        <div class="automation-card__footer">
          <button class="btn-text" @click="viewLogs(automation)">
            Ver Logs
          </button>
          <button class="btn-text" @click="testAutomation(automation)">
            Testar
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de Criação/Edição -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content modal-content--large">
        <div class="modal-header">
          <h2>{{ editingAutomation ? 'Editar Automação' : 'Nova Automação' }}</h2>
          <button class="modal-close" @click="closeModal">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <!-- Informações Básicas -->
          <div class="form-section">
            <h3>Informações Básicas</h3>
            <div class="form-group">
              <label>Nome *</label>
              <input v-model="formData.name" type="text" placeholder="Ex: Notificar quando mudar para Proposta" />
            </div>
            <div class="form-group">
              <label>Descrição</label>
              <textarea v-model="formData.description" rows="2" placeholder="Descreva o que esta automação faz"></textarea>
            </div>
          </div>

          <!-- Trigger -->
          <div class="form-section">
            <h3>Gatilho (Quando executar)</h3>
            <div class="form-group">
              <label>Tipo de Gatilho *</label>
              <select v-model="formData.trigger_type" @change="onTriggerChange">
                <option value="">Selecione...</option>
                <option v-for="t in triggerTypes" :key="t.value" :value="t.value">
                  {{ t.label }}
                </option>
              </select>
              <small v-if="selectedTriggerInfo">{{ selectedTriggerInfo.description }}</small>
            </div>

            <!-- Configuração específica do trigger -->
            <div v-if="formData.trigger_type === 'stage_changed'" class="form-row">
              <div class="form-group">
                <label>De Estágio (opcional)</label>
                <select v-model="formData.trigger_config.from_stage_id">
                  <option value="">Qualquer</option>
                  <option v-for="s in stages" :key="s.id" :value="s.id">{{ s.name }}</option>
                </select>
              </div>
              <div class="form-group">
                <label>Para Estágio (opcional)</label>
                <select v-model="formData.trigger_config.to_stage_id">
                  <option value="">Qualquer</option>
                  <option v-for="s in stages" :key="s.id" :value="s.id">{{ s.name }}</option>
                </select>
              </div>
            </div>

            <div v-if="formData.trigger_type === 'lead_stale'" class="form-row">
              <div class="form-group">
                <label>Dias Parado *</label>
                <input v-model.number="formData.trigger_config.days" type="number" min="1" />
              </div>
              <div class="form-group">
                <label>Estágio (opcional)</label>
                <select v-model="formData.trigger_config.stage_id">
                  <option value="">Qualquer</option>
                  <option v-for="s in stages" :key="s.id" :value="s.id">{{ s.name }}</option>
                </select>
              </div>
            </div>

            <div v-if="formData.trigger_type === 'deal_value_changed'" class="form-row">
              <div class="form-group">
                <label>Valor Mínimo</label>
                <input v-model.number="formData.trigger_config.min_value" type="number" min="0" />
              </div>
              <div class="form-group">
                <label>Valor Máximo</label>
                <input v-model.number="formData.trigger_config.max_value" type="number" min="0" />
              </div>
            </div>
          </div>

          <!-- Condições -->
          <div class="form-section">
            <div class="form-section__header">
              <h3>Condições (Filtros opcionais)</h3>
              <button class="btn-text" @click="addCondition">+ Adicionar Condição</button>
            </div>

            <div v-for="(condition, index) in formData.conditions" :key="index" class="condition-row">
              <select v-model="condition.field" class="condition-field">
                <option value="">Campo</option>
                <option v-for="f in conditionFields" :key="f.value" :value="f.value">{{ f.label }}</option>
              </select>
              <select v-model="condition.operator" class="condition-operator">
                <option value="">Operador</option>
                <option v-for="op in getOperatorsForField(condition.field)" :key="op" :value="op">
                  {{ operatorLabels[op] }}
                </option>
              </select>
              <input v-model="condition.value" type="text" placeholder="Valor" class="condition-value" />
              <button class="btn-icon btn-icon--danger" @click="removeCondition(index)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
              </button>
            </div>
          </div>

          <!-- Ações -->
          <div class="form-section">
            <div class="form-section__header">
              <h3>Ações (O que fazer) *</h3>
              <button class="btn-text" @click="addAction">+ Adicionar Ação</button>
            </div>

            <div v-for="(action, index) in formData.actions" :key="index" class="action-row">
              <div class="action-row__header">
                <span class="action-number">{{ index + 1 }}</span>
                <select v-model="action.action_type" @change="onActionTypeChange(action)" class="action-type">
                  <option value="">Selecione a ação</option>
                  <option v-for="a in actionTypes" :key="a.value" :value="a.value">{{ a.label }}</option>
                </select>
                <button class="btn-icon btn-icon--danger" @click="removeAction(index)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                </button>
              </div>

              <!-- Configuração da ação -->
              <div v-if="action.action_type" class="action-config">
                <template v-for="field in getActionConfigFields(action.action_type)" :key="field.key">
                  <div class="form-group">
                    <label>{{ field.label }} {{ field.required ? '*' : '' }}</label>
                    
                    <select
                      v-if="field.type === 'select' && field.source === 'stages'"
                      v-model="action.action_config[field.key]"
                    >
                      <option value="">Selecione...</option>
                      <option v-for="s in stages" :key="s.id" :value="s.id">{{ s.name }}</option>
                    </select>

                    <select
                      v-else-if="field.type === 'select' && field.source === 'users'"
                      v-model="action.action_config[field.key]"
                    >
                      <option value="">Selecione...</option>
                      <option v-for="u in users" :key="u.id" :value="u.id">{{ u.name }}</option>
                    </select>

                    <select
                      v-else-if="field.type === 'select' && field.options"
                      v-model="action.action_config[field.key]"
                    >
                      <option value="">Selecione...</option>
                      <option v-for="opt in field.options" :key="opt" :value="opt">{{ opt }}</option>
                    </select>

                    <textarea
                      v-else-if="field.type === 'textarea'"
                      v-model="action.action_config[field.key]"
                      rows="3"
                    ></textarea>

                    <input
                      v-else-if="field.type === 'number'"
                      v-model.number="action.action_config[field.key]"
                      type="number"
                    />

                    <input
                      v-else
                      v-model="action.action_config[field.key]"
                      type="text"
                    />
                  </div>
                </template>
              </div>
            </div>

            <p v-if="formData.actions.length === 0" class="empty-hint">
              Adicione pelo menos uma ação para a automação executar.
            </p>
          </div>

          <!-- Variáveis disponíveis -->
          <div class="form-section form-section--help">
            <h4>Variáveis Disponíveis</h4>
            <div class="variables-list">
              <code>{{contact.name}}</code>
              <code>{{contact.email}}</code>
              <code>{{contact.phone}}</code>
              <code>{{deal.value}}</code>
              <code>{{deal.stage}}</code>
              <code>{{assignee.name}}</code>
              <code>{{trigger.from_stage}}</code>
              <code>{{trigger.to_stage}}</code>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">Cancelar</button>
          <button class="btn-primary" @click="saveAutomation" :disabled="isSaving">
            {{ isSaving ? 'Salvando...' : (editingAutomation ? 'Salvar' : 'Criar') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de Logs -->
    <div v-if="showLogsModal" class="modal-overlay" @click.self="closeLogsModal">
      <div class="modal-content modal-content--large">
        <div class="modal-header">
          <h2>Logs: {{ selectedAutomation?.name }}</h2>
          <button class="modal-close" @click="closeLogsModal">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div v-if="logsLoading" class="automations-loading">
            <div class="loading-spinner"></div>
          </div>

          <div v-else-if="logs.length === 0" class="logs-empty">
            Nenhuma execução registrada ainda.
          </div>

          <div v-else class="logs-list">
            <div v-for="log in logs" :key="log.id" class="log-item" :class="`log-item--${log.status}`">
              <div class="log-item__header">
                <span class="log-status" :class="`log-status--${log.status}`">
                  {{ log.status_label }}
                </span>
                <span class="log-date">{{ formatDateTime(log.created_at) }}</span>
              </div>
              <div class="log-item__details">
                <span v-if="log.contact_name">Contato: {{ log.contact_name }}</span>
                <span v-if="log.conversation_display_id">Conversa #{{ log.conversation_display_id }}</span>
              </div>
              <div v-if="log.error_message" class="log-item__error">
                {{ log.error_message }}
              </div>
              <div v-if="log.actions_executed?.length" class="log-item__actions">
                <span v-for="(action, i) in log.actions_executed" :key="i" class="action-badge">
                  {{ action.action_type }}: {{ action.success ? '✓' : '✗' }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanAutomationsManager',
  props: {
    pipelineId: {
      type: [Number, String],
      required: true,
    },
    stages: {
      type: Array,
      default: () => [],
    },
    users: {
      type: Array,
      default: () => [],
    },
  },
  setup(props) {
    const route = useRoute();
    const accountId = computed(() => route.params.accountId);

    // State
    const isLoading = ref(true);
    const isSaving = ref(false);
    const automations = ref([]);
    const triggerTypes = ref([]);
    const actionTypes = ref([]);
    const conditionFields = ref([]);

    const showModal = ref(false);
    const editingAutomation = ref(null);
    const formData = ref(getEmptyFormData());

    const showLogsModal = ref(false);
    const selectedAutomation = ref(null);
    const logs = ref([]);
    const logsLoading = ref(false);

    const operatorLabels = {
      equals: 'Igual a',
      not_equals: 'Diferente de',
      greater_than: 'Maior que',
      less_than: 'Menor que',
      greater_or_equal: 'Maior ou igual',
      less_or_equal: 'Menor ou igual',
      contains: 'Contém',
      not_contains: 'Não contém',
      starts_with: 'Começa com',
      ends_with: 'Termina com',
      is_empty: 'Está vazio',
      is_not_empty: 'Não está vazio',
    };

    function getEmptyFormData() {
      return {
        name: '',
        description: '',
        trigger_type: '',
        trigger_config: {},
        is_active: true,
        conditions: [],
        actions: [],
      };
    }

    const selectedTriggerInfo = computed(() => {
      return triggerTypes.value.find(t => t.value === formData.value.trigger_type);
    });

    // Load data
    async function loadAutomations() {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getAutomations(accountId.value, props.pipelineId);
        automations.value = response.data.automations;
        triggerTypes.value = response.data.meta.trigger_types;
        actionTypes.value = response.data.meta.action_types;
        conditionFields.value = response.data.meta.condition_fields;
      } catch (error) {
        console.error('Erro ao carregar automações:', error);
      } finally {
        isLoading.value = false;
      }
    }

    // Modal handlers
    function openCreateModal() {
      editingAutomation.value = null;
      formData.value = getEmptyFormData();
      showModal.value = true;
    }

    function openEditModal(automation) {
      editingAutomation.value = automation;
      formData.value = {
        name: automation.name,
        description: automation.description,
        trigger_type: automation.trigger_type,
        trigger_config: { ...automation.trigger_config },
        is_active: automation.is_active,
        conditions: automation.conditions.map(c => ({ ...c })),
        actions: automation.actions.map(a => ({
          ...a,
          action_config: { ...a.action_config },
        })),
      };
      showModal.value = true;
    }

    function closeModal() {
      showModal.value = false;
      editingAutomation.value = null;
      formData.value = getEmptyFormData();
    }

    // Save automation
    async function saveAutomation() {
      if (!formData.value.name || !formData.value.trigger_type) {
        alert('Preencha o nome e selecione um gatilho');
        return;
      }

      if (formData.value.actions.length === 0) {
        alert('Adicione pelo menos uma ação');
        return;
      }

      isSaving.value = true;

      try {
        const data = {
          ...formData.value,
          conditions_attributes: formData.value.conditions.map((c, i) => ({
            ...c,
            position: i,
          })),
          actions_attributes: formData.value.actions.map((a, i) => ({
            ...a,
            position: i,
          })),
        };

        if (editingAutomation.value) {
          await KanbanAPI.updateAutomation(
            accountId.value,
            props.pipelineId,
            editingAutomation.value.id,
            data
          );
        } else {
          await KanbanAPI.createAutomation(accountId.value, props.pipelineId, data);
        }

        await loadAutomations();
        closeModal();
      } catch (error) {
        console.error('Erro ao salvar automação:', error);
        alert('Erro ao salvar automação');
      } finally {
        isSaving.value = false;
      }
    }

    // Actions
    async function toggleActive(automation) {
      try {
        await KanbanAPI.toggleAutomation(accountId.value, props.pipelineId, automation.id);
        await loadAutomations();
      } catch (error) {
        console.error('Erro ao alternar automação:', error);
      }
    }

    async function confirmDelete(automation) {
      if (!confirm(`Excluir a automação "${automation.name}"?`)) return;

      try {
        await KanbanAPI.deleteAutomation(accountId.value, props.pipelineId, automation.id);
        await loadAutomations();
      } catch (error) {
        console.error('Erro ao excluir automação:', error);
      }
    }

    async function testAutomation(automation) {
      try {
        const response = await KanbanAPI.testAutomation(
          accountId.value,
          props.pipelineId,
          automation.id
        );
        alert(response.data.message);
      } catch (error) {
        alert('Erro ao testar: ' + (error.response?.data?.error || error.message));
      }
    }

    // Logs
    async function viewLogs(automation) {
      selectedAutomation.value = automation;
      showLogsModal.value = true;
      logsLoading.value = true;

      try {
        const response = await KanbanAPI.getAutomationLogs(
          accountId.value,
          props.pipelineId,
          automation.id
        );
        logs.value = response.data.logs;
      } catch (error) {
        console.error('Erro ao carregar logs:', error);
      } finally {
        logsLoading.value = false;
      }
    }

    function closeLogsModal() {
      showLogsModal.value = false;
      selectedAutomation.value = null;
      logs.value = [];
    }

    // Form helpers
    function onTriggerChange() {
      formData.value.trigger_config = {};
    }

    function addCondition() {
      formData.value.conditions.push({
        field: '',
        operator: '',
        value: '',
      });
    }

    function removeCondition(index) {
      formData.value.conditions.splice(index, 1);
    }

    function addAction() {
      formData.value.actions.push({
        action_type: '',
        action_config: {},
      });
    }

    function removeAction(index) {
      formData.value.actions.splice(index, 1);
    }

    function onActionTypeChange(action) {
      action.action_config = {};
    }

    function getOperatorsForField(field) {
      const fieldConfig = conditionFields.value.find(f => f.value === field);
      const type = fieldConfig?.type || 'text';
      
      const operatorsByType = {
        text: ['equals', 'not_equals', 'contains', 'not_contains', 'starts_with', 'ends_with', 'is_empty', 'is_not_empty'],
        number: ['equals', 'not_equals', 'greater_than', 'less_than', 'greater_or_equal', 'less_or_equal'],
        select: ['equals', 'not_equals', 'is_empty', 'is_not_empty'],
      };

      return operatorsByType[type] || operatorsByType.text;
    }

    function getActionConfigFields(actionType) {
      const actionConfig = actionTypes.value.find(a => a.value === actionType);
      return actionConfig?.config_fields || [];
    }

    // Formatting
    function formatDate(date) {
      if (!date) return '';
      return new Date(date).toLocaleDateString('pt-BR');
    }

    function formatDateTime(date) {
      if (!date) return '';
      return new Date(date).toLocaleString('pt-BR');
    }

    onMounted(() => {
      loadAutomations();
    });

    return {
      isLoading,
      isSaving,
      automations,
      triggerTypes,
      actionTypes,
      conditionFields,
      showModal,
      editingAutomation,
      formData,
      selectedTriggerInfo,
      operatorLabels,
      showLogsModal,
      selectedAutomation,
      logs,
      logsLoading,
      openCreateModal,
      openEditModal,
      closeModal,
      saveAutomation,
      toggleActive,
      confirmDelete,
      testAutomation,
      viewLogs,
      closeLogsModal,
      onTriggerChange,
      addCondition,
      removeCondition,
      addAction,
      removeAction,
      onActionTypeChange,
      getOperatorsForField,
      getActionConfigFields,
      formatDate,
      formatDateTime,
    };
  },
};
</script>

<style scoped>
.automations-manager {
  padding: 24px;
}

.automations-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.automations-header__left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.automations-header__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 20px;
  font-weight: 600;
  margin: 0;
}

.automations-header__icon {
  width: 24px;
  height: 24px;
  color: var(--w-500);
}

.automations-header__count {
  color: var(--s-500);
  font-size: 14px;
}

/* Buttons */
.btn-primary {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: var(--w-500);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary:hover {
  background: var(--w-600);
}

.btn-primary svg {
  width: 16px;
  height: 16px;
}

.btn-secondary {
  padding: 8px 16px;
  background: var(--s-100);
  color: var(--s-700);
  border: 1px solid var(--s-200);
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.btn-text {
  padding: 4px 8px;
  background: none;
  border: none;
  color: var(--w-500);
  font-size: 13px;
  cursor: pointer;
}

.btn-text:hover {
  text-decoration: underline;
}

.btn-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: var(--s-50);
  border: 1px solid var(--s-200);
  border-radius: 6px;
  cursor: pointer;
}

.btn-icon svg {
  width: 16px;
  height: 16px;
  color: var(--s-600);
}

.btn-icon--success { background: rgba(16, 185, 129, 0.1); border-color: #10b981; }
.btn-icon--success svg { color: #10b981; }

.btn-icon--muted { background: var(--s-100); }

.btn-icon--danger:hover { background: rgba(239, 68, 68, 0.1); border-color: #ef4444; }
.btn-icon--danger:hover svg { color: #ef4444; }

/* Loading & Empty */
.automations-loading,
.automations-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
  text-align: center;
  color: var(--s-500);
}

.automations-empty__icon {
  width: 48px;
  height: 48px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.automations-empty h3 {
  margin: 0 0 8px;
  color: var(--s-700);
}

.automations-empty p {
  margin: 0 0 16px;
  max-width: 300px;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--s-200);
  border-top-color: var(--w-500);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Automation Cards */
.automations-list {
  display: grid;
  gap: 16px;
}

.automation-card {
  background: var(--white);
  border: 1px solid var(--s-200);
  border-radius: 12px;
  padding: 16px;
}

.automation-card--inactive {
  opacity: 0.6;
  background: var(--s-50);
}

.automation-card__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.automation-card__info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.automation-card__name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.automation-card__trigger {
  padding: 2px 8px;
  background: var(--s-100);
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
  color: var(--s-600);
}

.automation-card__actions {
  display: flex;
  gap: 6px;
}

.automation-card__description {
  margin: 0 0 12px;
  font-size: 13px;
  color: var(--s-500);
}

.automation-card__details {
  display: flex;
  gap: 16px;
  margin-bottom: 12px;
  font-size: 13px;
}

.detail-label {
  color: var(--s-500);
}

.detail-value {
  color: var(--s-700);
  font-weight: 500;
}

.automation-card__stats {
  display: flex;
  gap: 16px;
  font-size: 12px;
  color: var(--s-400);
}

.stat {
  display: flex;
  align-items: center;
  gap: 4px;
}

.stat svg {
  width: 14px;
  height: 14px;
}

.automation-card__footer {
  display: flex;
  gap: 12px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--s-100);
}

/* Modal */
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
}

.modal-content {
  background: var(--white);
  border-radius: 16px;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-content--large {
  max-width: 800px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--s-100);
}

.modal-header h2 {
  margin: 0;
  font-size: 18px;
}

.modal-close {
  background: none;
  border: none;
  padding: 4px;
  cursor: pointer;
}

.modal-close svg {
  width: 20px;
  height: 20px;
  color: var(--s-500);
}

.modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 20px;
  border-top: 1px solid var(--s-100);
}

/* Form */
.form-section {
  margin-bottom: 24px;
}

.form-section h3 {
  margin: 0 0 12px;
  font-size: 14px;
  font-weight: 600;
  color: var(--s-700);
}

.form-section__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.form-section__header h3 {
  margin: 0;
}

.form-group {
  margin-bottom: 12px;
}

.form-group label {
  display: block;
  margin-bottom: 4px;
  font-size: 13px;
  font-weight: 500;
  color: var(--s-600);
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 14px;
}

.form-group small {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  color: var(--s-400);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* Conditions */
.condition-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.condition-field { flex: 1; }
.condition-operator { width: 140px; }
.condition-value { flex: 1; }

/* Actions */
.action-row {
  background: var(--s-50);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
}

.action-row__header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.action-number {
  width: 24px;
  height: 24px;
  background: var(--w-500);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
}

.action-type {
  flex: 1;
}

.action-config {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--s-200);
}

.empty-hint {
  color: var(--s-400);
  font-size: 13px;
  text-align: center;
  padding: 16px;
}

/* Variables */
.form-section--help {
  background: var(--s-50);
  padding: 12px;
  border-radius: 8px;
}

.form-section--help h4 {
  margin: 0 0 8px;
  font-size: 12px;
  color: var(--s-500);
}

.variables-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.variables-list code {
  padding: 2px 6px;
  background: var(--s-200);
  border-radius: 4px;
  font-size: 11px;
}

/* Logs */
.logs-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.log-item {
  padding: 12px;
  border: 1px solid var(--s-200);
  border-radius: 8px;
}

.log-item--success { border-left: 3px solid #10b981; }
.log-item--failed { border-left: 3px solid #ef4444; }

.log-item__header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.log-status {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
}

.log-status--success { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.log-status--failed { background: rgba(239, 68, 68, 0.1); color: #ef4444; }
.log-status--pending { background: var(--s-100); color: var(--s-500); }

.log-date {
  font-size: 12px;
  color: var(--s-400);
}

.log-item__details {
  font-size: 13px;
  color: var(--s-600);
}

.log-item__error {
  margin-top: 8px;
  padding: 8px;
  background: rgba(239, 68, 68, 0.1);
  border-radius: 4px;
  font-size: 12px;
  color: #ef4444;
}

.log-item__actions {
  display: flex;
  gap: 4px;
  margin-top: 8px;
}

.action-badge {
  padding: 2px 6px;
  background: var(--s-100);
  border-radius: 4px;
  font-size: 11px;
}

.logs-empty {
  text-align: center;
  padding: 40px;
  color: var(--s-400);
}

/* Dark Mode */
.dark .automation-card {
  background: var(--s-800);
  border-color: var(--s-700);
}

.dark .modal-content {
  background: var(--s-900);
}

.dark .form-group input,
.dark .form-group select,
.dark .form-group textarea {
  background: var(--s-800);
  border-color: var(--s-700);
  color: var(--s-100);
}

.dark .action-row {
  background: var(--s-800);
}

.dark .log-item {
  background: var(--s-800);
  border-color: var(--s-700);
}
</style>
