<template>
  <div class="crm-section">
    <!-- Loading -->
    <div v-if="isLoading" class="crm-section__loading">
      <span class="loading-spinner"></span>
      Carregando...
    </div>

    <!-- Conteúdo -->
    <div v-else>
      <!-- Não está no CRM -->
      <div v-if="!isInCrm" class="crm-section__empty">
        <p>Esta conversa não está no CRM.</p>
        <div class="crm-section__add-form">
          <select v-model="selectedPipelineId" class="crm-section__select">
            <option :value="null">Selecione um pipeline...</option>
            <option v-for="pipeline in pipelines" :key="pipeline.id" :value="pipeline.id">
              {{ pipeline.name }}
            </option>
          </select>
          <select 
            v-if="selectedPipelineId && availableStages.length > 0" 
            v-model="selectedStageId" 
            class="crm-section__select"
          >
            <option :value="null">Selecione um estágio...</option>
            <option v-for="stage in availableStages" :key="stage.id" :value="stage.id">
              {{ stage.name }}
            </option>
          </select>
          <button 
            v-if="selectedStageId"
            class="crm-section__btn crm-section__btn--primary"
            :disabled="isSaving"
            @click="addToCrm"
          >
            {{ isSaving ? 'Adicionando...' : 'Adicionar ao CRM' }}
          </button>
        </div>
      </div>

      <!-- Está no CRM -->
      <div v-else class="crm-section__content">
        <!-- Info do Pipeline/Estágio atual -->
        <div class="crm-section__current">
          <div class="crm-section__pipeline-info">
            <span class="crm-section__label">Pipeline:</span>
            <span class="crm-section__value">{{ currentPipelineName }}</span>
          </div>
          <div class="crm-section__stage-selector">
            <span class="crm-section__label">Estágio:</span>
            <select v-model="currentStageIdLocal" class="crm-section__select" @change="onStageChange">
              <option v-for="stage in currentPipelineStages" :key="stage.id" :value="stage.id">
                {{ stage.name }}
              </option>
            </select>
          </div>
        </div>

        <!-- Valor do Negócio -->
        <div class="crm-section__field">
          <label class="crm-section__label">Valor do Negócio</label>
          <div class="crm-section__currency">
            <span class="crm-section__currency-prefix">R$</span>
            <input
              type="number"
              step="0.01"
              class="crm-section__input crm-section__input--currency"
              :value="dealValue"
              placeholder="0,00"
              @blur="updateDealValue($event.target.value)"
              @keyup.enter="updateDealValue($event.target.value)"
            />
          </div>
        </div>

        <!-- Status Ganho/Perdido -->
        <div class="crm-section__field">
          <label class="crm-section__label">Status do Negócio</label>
          <div v-if="closedWon === null || closedWon === undefined" class="crm-section__status-buttons">
            <button 
              class="crm-section__status-btn crm-section__status-btn--won"
              @click="markAsWon"
            >
              ✓ Marcar Ganho
            </button>
            <button 
              class="crm-section__status-btn crm-section__status-btn--lost"
              @click="showLossModal = true"
            >
              ✗ Marcar Perdido
            </button>
          </div>
          <div v-else class="crm-section__status-result">
            <span :class="closedWon ? 'crm-section__won' : 'crm-section__lost'">
              {{ closedWon ? '✓ GANHO' : '✗ PERDIDO' }}
              <span v-if="!closedWon && closedReason"> - {{ closedReason }}</span>
            </span>
            <button class="crm-section__reset-btn" @click="resetStatus" title="Resetar status">
              ↺
            </button>
          </div>
        </div>

        <!-- Campos Personalizados -->
        <div v-if="customFields.length > 0" class="crm-section__custom-fields">
          <label class="crm-section__label crm-section__label--section">Campos Personalizados</label>
          
          <div v-for="field in customFields" :key="field.id" class="crm-section__custom-field">
            <label class="crm-section__field-label">
              {{ field.name }}
              <span v-if="field.required" class="crm-section__required">*</span>
            </label>

            <!-- Text -->
            <input
              v-if="field.field_type === 'text'"
              type="text"
              class="crm-section__input"
              :value="getFieldValue(field.field_key)"
              :placeholder="field.description || 'Digite...'"
              @blur="updateCustomField(field.field_key, $event.target.value)"
            />

            <!-- Textarea -->
            <textarea
              v-else-if="field.field_type === 'textarea'"
              class="crm-section__textarea"
              rows="2"
              :value="getFieldValue(field.field_key)"
              @blur="updateCustomField(field.field_key, $event.target.value)"
            />

            <!-- Number -->
            <input
              v-else-if="field.field_type === 'number'"
              type="number"
              class="crm-section__input"
              :value="getFieldValue(field.field_key)"
              @blur="updateCustomField(field.field_key, $event.target.value)"
            />

            <!-- Currency -->
            <div v-else-if="field.field_type === 'currency'" class="crm-section__currency">
              <span class="crm-section__currency-prefix">R$</span>
              <input
                type="number"
                step="0.01"
                class="crm-section__input crm-section__input--currency"
                :value="getFieldValue(field.field_key)"
                @blur="updateCustomField(field.field_key, $event.target.value)"
              />
            </div>

            <!-- Select -->
            <select
              v-else-if="field.field_type === 'select'"
              class="crm-section__select"
              :value="getFieldValue(field.field_key)"
              @change="updateCustomField(field.field_key, $event.target.value)"
            >
              <option value="">Selecione...</option>
              <option v-for="opt in field.select_options" :key="opt" :value="opt">
                {{ opt }}
              </option>
            </select>

            <!-- Date -->
            <input
              v-else-if="field.field_type === 'date'"
              type="date"
              class="crm-section__input"
              :value="getFieldValue(field.field_key)"
              @change="updateCustomField(field.field_key, $event.target.value)"
            />

            <!-- Checkbox -->
            <label v-else-if="field.field_type === 'checkbox'" class="crm-section__checkbox">
              <input
                type="checkbox"
                :checked="getFieldValue(field.field_key) === 'true'"
                @change="updateCustomField(field.field_key, $event.target.checked ? 'true' : 'false')"
              />
              Sim
            </label>
          </div>
        </div>

        <!-- Remover do CRM -->
        <div class="crm-section__remove">
          <button class="crm-section__remove-btn" @click="confirmRemove">
            🗑️ Remover do CRM
          </button>
          <p class="crm-section__remove-hint">Remove apenas do CRM, não apaga a conversa.</p>
        </div>
      </div>
    </div>

    <!-- Modal de Motivo de Perda -->
    <div v-if="showLossModal" class="crm-section__modal-overlay" @click="showLossModal = false">
      <div class="crm-section__modal" @click.stop>
        <h4>Motivo da Perda</h4>
        <select v-model="lossReason" class="crm-section__select">
          <option value="">Selecione...</option>
          <option value="Preço">Preço</option>
          <option value="Concorrência">Concorrência</option>
          <option value="Timing">Timing / Não é o momento</option>
          <option value="Sem resposta">Sem resposta</option>
          <option value="Desistiu">Desistiu</option>
          <option value="Outro">Outro</option>
        </select>
        <input
          v-if="lossReason === 'Outro'"
          v-model="customLossReason"
          type="text"
          placeholder="Especifique..."
          class="crm-section__input"
        />
        <div class="crm-section__modal-actions">
          <button class="crm-section__btn" @click="showLossModal = false">Cancelar</button>
          <button 
            class="crm-section__btn crm-section__btn--danger" 
            :disabled="!lossReason || (lossReason === 'Outro' && !customLossReason)"
            @click="confirmLoss"
          >
            Confirmar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'CrmSection',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    currentStageId: {
      type: Number,
      default: null,
    },
    initialDealValue: {
      type: [Number, String],
      default: null,
    },
    initialClosedWon: {
      type: Boolean,
      default: null,
    },
    initialClosedReason: {
      type: String,
      default: null,
    },
  },
  emits: ['updated'],
  setup(props, { emit }) {
    const store = useStore();
    const accountId = computed(() => store.getters.getCurrentAccountId);

    // State
    const isLoading = ref(true);
    const isSaving = ref(false);
    const pipelines = ref([]);
    const selectedPipelineId = ref(null);
    const selectedStageId = ref(null);
    const currentStageIdLocal = ref(props.currentStageId);
    const dealValue = ref(props.initialDealValue);
    const closedWon = ref(props.initialClosedWon);
    const closedReason = ref(props.initialClosedReason);
    const customFields = ref([]);
    const customFieldValues = ref({});
    const showLossModal = ref(false);
    const lossReason = ref('');
    const customLossReason = ref('');

    // Computed
    const isInCrm = computed(() => currentStageIdLocal.value !== null);
    
    const currentPipeline = computed(() => {
      if (!currentStageIdLocal.value) return null;
      return pipelines.value.find(p => 
        p.kanban_stages?.some(s => s.id === currentStageIdLocal.value)
      );
    });

    const currentPipelineName = computed(() => currentPipeline.value?.name || 'N/A');

    const currentPipelineStages = computed(() => currentPipeline.value?.kanban_stages || []);

    const availableStages = computed(() => {
      if (!selectedPipelineId.value) return [];
      const pipeline = pipelines.value.find(p => p.id === selectedPipelineId.value);
      return pipeline?.kanban_stages || [];
    });

    // Methods
    const loadData = async () => {
      isLoading.value = true;
      try {
        // Carregar pipelines
        const pipelinesRes = await KanbanAPI.getPipelines(accountId.value);
        pipelines.value = pipelinesRes.data.filter(p => p.pipeline_type === 'conversations');

        // Se está no CRM, carregar campos personalizados
        if (props.currentStageId) {
          currentStageIdLocal.value = props.currentStageId;
          await loadCustomFields();
        }
      } catch (error) {
        console.error('Erro ao carregar dados do CRM:', error);
      } finally {
        isLoading.value = false;
      }
    };

    const loadCustomFields = async () => {
      try {
        const response = await KanbanAPI.getCustomFieldValues(accountId.value, props.conversationId);
        customFields.value = response.data.fields || [];
        customFieldValues.value = response.data.values || {};
      } catch (error) {
        console.error('Erro ao carregar campos personalizados:', error);
      }
    };

    const getFieldValue = (fieldKey) => {
      return customFieldValues.value[fieldKey]?.value || '';
    };

    const addToCrm = async () => {
      if (!selectedStageId.value) return;
      isSaving.value = true;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, selectedStageId.value);
        currentStageIdLocal.value = selectedStageId.value;
        await loadCustomFields();
        emit('updated', { stageId: selectedStageId.value });
      } catch (error) {
        console.error('Erro ao adicionar ao CRM:', error);
      } finally {
        isSaving.value = false;
      }
    };

    const onStageChange = async () => {
      isSaving.value = true;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, currentStageIdLocal.value);
        emit('updated', { stageId: currentStageIdLocal.value });
      } catch (error) {
        console.error('Erro ao atualizar estágio:', error);
      } finally {
        isSaving.value = false;
      }
    };

    const updateDealValue = async (value) => {
      const numValue = parseFloat(value) || null;
      if (numValue === dealValue.value) return;
      
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { deal_value: numValue });
        dealValue.value = numValue;
        emit('updated', { deal_value: numValue });
      } catch (error) {
        console.error('Erro ao atualizar valor:', error);
      }
    };

    const markAsWon = async () => {
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { closed_won: true });
        closedWon.value = true;
        emit('updated', { closed_won: true });
      } catch (error) {
        console.error('Erro ao marcar como ganho:', error);
      }
    };

    const confirmLoss = async () => {
      const reason = lossReason.value === 'Outro' ? customLossReason.value : lossReason.value;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { 
          closed_won: false, 
          closed_reason: reason 
        });
        closedWon.value = false;
        closedReason.value = reason;
        showLossModal.value = false;
        lossReason.value = '';
        customLossReason.value = '';
        emit('updated', { closed_won: false, closed_reason: reason });
      } catch (error) {
        console.error('Erro ao marcar como perdido:', error);
      }
    };

    const resetStatus = async () => {
      if (!confirm('Resetar o status do negócio?')) return;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { 
          closed_won: null, 
          closed_reason: null 
        });
        closedWon.value = null;
        closedReason.value = null;
        emit('updated', { closed_won: null, closed_reason: null });
      } catch (error) {
        console.error('Erro ao resetar status:', error);
      }
    };

    const updateCustomField = async (fieldKey, value) => {
      try {
        await KanbanAPI.bulkUpdateCustomFieldValues(accountId.value, props.conversationId, {
          [fieldKey]: value
        });
        if (!customFieldValues.value[fieldKey]) {
          customFieldValues.value[fieldKey] = {};
        }
        customFieldValues.value[fieldKey].value = value;
      } catch (error) {
        console.error('Erro ao atualizar campo:', error);
      }
    };

    const confirmRemove = async () => {
      if (!confirm('Remover esta conversa do CRM? A conversa não será apagada.')) return;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, null);
        currentStageIdLocal.value = null;
        customFields.value = [];
        customFieldValues.value = {};
        emit('updated', { stageId: null });
      } catch (error) {
        console.error('Erro ao remover do CRM:', error);
      }
    };

    // Watchers
    watch(() => props.currentStageId, (newVal) => {
      currentStageIdLocal.value = newVal;
      if (newVal) loadCustomFields();
    });

    watch(() => props.initialDealValue, (newVal) => {
      dealValue.value = newVal;
    });

    watch(() => props.initialClosedWon, (newVal) => {
      closedWon.value = newVal;
    });

    watch(() => props.initialClosedReason, (newVal) => {
      closedReason.value = newVal;
    });

    onMounted(() => {
      loadData();
    });

    return {
      isLoading,
      isSaving,
      pipelines,
      selectedPipelineId,
      selectedStageId,
      currentStageIdLocal,
      dealValue,
      closedWon,
      closedReason,
      customFields,
      customFieldValues,
      showLossModal,
      lossReason,
      customLossReason,
      isInCrm,
      currentPipelineName,
      currentPipelineStages,
      availableStages,
      getFieldValue,
      addToCrm,
      onStageChange,
      updateDealValue,
      markAsWon,
      confirmLoss,
      resetStatus,
      updateCustomField,
      confirmRemove,
    };
  },
};
</script>

<style scoped>
.crm-section {
  padding: 8px 0;
}

.crm-section__loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 20px;
  color: var(--s-500);
  font-size: 13px;
}

.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid var(--s-200);
  border-top-color: var(--w-500);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.crm-section__empty {
  text-align: center;
  padding: 12px;
}

.crm-section__empty p {
  color: var(--s-500);
  font-size: 13px;
  margin-bottom: 12px;
}

.crm-section__add-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.crm-section__content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.crm-section__current {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  background-color: var(--s-50);
  border-radius: 6px;
}

.dark .crm-section__current {
  background-color: var(--s-800);
}

.crm-section__pipeline-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}

.crm-section__stage-selector {
  display: flex;
  align-items: center;
  gap: 6px;
}

.crm-section__label {
  font-size: 12px;
  font-weight: 500;
  color: var(--s-600);
  flex-shrink: 0;
}

.dark .crm-section__label {
  color: var(--s-400);
}

.crm-section__label--section {
  font-size: 13px;
  font-weight: 600;
  color: var(--s-700);
  margin-bottom: 8px;
  display: block;
}

.dark .crm-section__label--section {
  color: var(--s-300);
}

.crm-section__value {
  font-size: 12px;
  font-weight: 600;
  color: var(--s-800);
}

.dark .crm-section__value {
  color: var(--s-200);
}

.crm-section__field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.crm-section__field-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--s-600);
}

.dark .crm-section__field-label {
  color: var(--s-400);
}

.crm-section__required {
  color: #ef4444;
}

.crm-section__select,
.crm-section__input,
.crm-section__textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 13px;
  background-color: var(--color-background);
  color: var(--color-body);
}

.dark .crm-section__select,
.dark .crm-section__input,
.dark .crm-section__textarea {
  background-color: var(--s-800);
  border-color: var(--s-600);
  color: var(--s-100);
}

.crm-section__select:focus,
.crm-section__input:focus,
.crm-section__textarea:focus {
  outline: none;
  border-color: var(--w-500);
}

.crm-section__currency {
  display: flex;
  align-items: center;
}

.crm-section__currency-prefix {
  padding: 8px 10px;
  background-color: var(--s-100);
  border: 1px solid var(--s-200);
  border-right: none;
  border-radius: 6px 0 0 6px;
  font-size: 13px;
  color: var(--s-600);
}

.dark .crm-section__currency-prefix {
  background-color: var(--s-700);
  border-color: var(--s-600);
  color: var(--s-300);
}

.crm-section__input--currency {
  border-radius: 0 6px 6px 0;
}

.crm-section__textarea {
  resize: vertical;
  min-height: 60px;
}

.crm-section__checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
}

/* Status Buttons */
.crm-section__status-buttons {
  display: flex;
  gap: 8px;
}

.crm-section__status-btn {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.crm-section__status-btn--won {
  background-color: #d1fae5;
  color: #065f46;
}

.crm-section__status-btn--won:hover {
  background-color: #10b981;
  color: white;
}

.crm-section__status-btn--lost {
  background-color: #fee2e2;
  color: #991b1b;
}

.crm-section__status-btn--lost:hover {
  background-color: #ef4444;
  color: white;
}

.crm-section__status-result {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-radius: 6px;
  background-color: var(--s-50);
}

.dark .crm-section__status-result {
  background-color: var(--s-800);
}

.crm-section__won {
  color: #059669;
  font-weight: 600;
  font-size: 13px;
}

.crm-section__lost {
  color: #dc2626;
  font-weight: 600;
  font-size: 13px;
}

.crm-section__reset-btn {
  background: none;
  border: none;
  font-size: 16px;
  cursor: pointer;
  color: var(--s-400);
  padding: 4px;
}

.crm-section__reset-btn:hover {
  color: var(--s-600);
}

/* Custom Fields */
.crm-section__custom-fields {
  padding-top: 12px;
  border-top: 1px solid var(--s-200);
}

.dark .crm-section__custom-fields {
  border-color: var(--s-700);
}

.crm-section__custom-field {
  margin-bottom: 12px;
}

/* Remove Button */
.crm-section__remove {
  padding-top: 16px;
  border-top: 1px solid var(--s-200);
  text-align: center;
}

.dark .crm-section__remove {
  border-color: var(--s-700);
}

.crm-section__remove-btn {
  padding: 8px 16px;
  background-color: transparent;
  border: 1px solid #ef4444;
  color: #ef4444;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.crm-section__remove-btn:hover {
  background-color: #ef4444;
  color: white;
}

.crm-section__remove-hint {
  font-size: 11px;
  color: var(--s-400);
  margin-top: 6px;
}

/* Buttons */
.crm-section__btn {
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  border: 1px solid var(--s-300);
  background-color: var(--color-background);
  color: var(--s-700);
}

.crm-section__btn--primary {
  background-color: var(--w-500);
  border-color: var(--w-500);
  color: white;
}

.crm-section__btn--primary:hover {
  background-color: var(--w-600);
}

.crm-section__btn--danger {
  background-color: #ef4444;
  border-color: #ef4444;
  color: white;
}

.crm-section__btn--danger:hover {
  background-color: #dc2626;
}

.crm-section__btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modal */
.crm-section__modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.crm-section__modal {
  background: var(--color-background);
  border-radius: 8px;
  padding: 20px;
  min-width: 300px;
  max-width: 400px;
}

.dark .crm-section__modal {
  background-color: var(--s-800);
}

.crm-section__modal h4 {
  margin: 0 0 16px 0;
  font-size: 16px;
  color: var(--s-800);
}

.dark .crm-section__modal h4 {
  color: var(--s-100);
}

.crm-section__modal-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
