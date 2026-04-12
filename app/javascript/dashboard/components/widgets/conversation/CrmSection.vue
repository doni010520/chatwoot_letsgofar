<template>
  <div class="cw-crm-panel">
    
    <!-- Header da Seção -->
    <div class="cw-crm-header">
      <h3 class="cw-crm-title">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mr-1"><rect width="20" height="14" x="2" y="7" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>
        Negócios (CRM)
      </h3>
      <div v-if="isInCrm && !isSaving" class="cw-crm-badge-saved">Salvo</div>
      <div v-if="isSaving" class="cw-crm-loading">Salvando...</div>
    </div>

    <!-- Loading Inicial -->
    <div v-if="isLoading" class="p-4 flex justify-center">
      <div class="cw-spinner"></div>
    </div>

    <div v-else>
      <!-- ESTADO 1: NÃO ESTÁ NO CRM (Empty State) -->
      <div v-if="!isInCrm" class="cw-crm-empty">
        <p class="text-sm text-slate-500 mb-3 text-center">Nenhum negócio vinculado a esta conversa.</p>
        
        <div class="space-y-2">
          <select v-model="selectedPipelineId" class="cw-input">
            <option :value="null">Selecione o Funil...</option>
            <option v-for="pipeline in pipelines" :key="pipeline.id" :value="pipeline.id">
              {{ pipeline.name }}
            </option>
          </select>

          <select v-if="selectedPipelineId" v-model="selectedStageId" class="cw-input">
            <option :value="null">Selecione o Estágio...</option>
            <option v-for="stage in availableStages" :key="stage.id" :value="stage.id">
              {{ stage.name }}
            </option>
          </select>

          <button 
            v-if="selectedStageId"
            class="cw-btn cw-btn-primary w-full mt-2"
            :disabled="isSaving"
            @click="addToCrm"
          >
            {{ isSaving ? 'Criando...' : 'Iniciar Negócio' }}
          </button>
        </div>
      </div>

      <!-- ESTADO 2: EDITOR (Active State) -->
      <div v-else class="cw-crm-content">
        
        <!-- Highlight Card: Valor & Estágio -->
        <div class="cw-card-highlight">
          <!-- Valor (Input Grande) -->
          <div class="cw-value-wrapper">
             <span class="cw-currency-symbol">R$</span>
             <input 
                type="number" 
                step="0.01"
                class="cw-input-value"
                :value="dealValue"
                placeholder="0,00"
                :disabled="closedWon !== null"
                @blur="updateDealValue($event.target.value)"
                @keyup.enter="updateDealValue($event.target.value)"
             />
          </div>

          <!-- Seletor de Estágio (Se aberto) ou Texto (Se fechado) -->
          <div class="flex items-center">
             <span class="text-xs text-slate-400 mr-2">Etapa:</span>
             
             <div v-if="closedWon !== null" class="text-sm font-medium text-slate-600">
                {{ currentStageName }}
             </div>

             <div v-else class="cw-input-ghost flex-1">
                <select v-model="currentStageIdLocal" class="bg-transparent w-full outline-none cursor-pointer" @change="onStageChange">
                    <option v-for="stage in currentPipelineStages" :key="stage.id" :value="stage.id">
                      {{ stage.name }}
                    </option>
                </select>
             </div>
          </div>
        </div>

        <!-- Barra de Status (Ações) -->
        <div class="cw-status-bar">
           <!-- Se Fechado -->
           <div v-if="closedWon !== null && closedWon !== undefined" class="flex items-center justify-between w-full">
              <span :class="['cw-badge', closedWon ? 'cw-badge-won' : 'cw-badge-lost']">
                {{ closedWon ? '✓ GANHO' : '✗ PERDIDO' }}
              </span>
              <button @click="resetStatus" class="cw-btn-icon" title="Reabrir Negócio">
                 <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
              </button>
           </div>
           
           <!-- Se Aberto -->
           <div v-else class="grid grid-cols-2 gap-2 w-full">
              <button class="cw-btn cw-btn-outline-success" @click="markAsWon">
                 <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="mr-1"><polyline points="20 6 9 17 4 12"/></svg>
                 Ganho
              </button>
              <button class="cw-btn cw-btn-outline-danger" @click="showLossModal = true">
                 <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="mr-1"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                 Perdido
              </button>
           </div>
        </div>

        <!-- Campos Personalizados -->
        <div v-if="customFields.length > 0" class="cw-fields-list" :class="{ 'opacity-60 pointer-events-none': closedWon !== null }">
           <div v-for="field in customFields" :key="field.id" class="cw-field-group">
              <label class="cw-label">
                {{ field.name }}
                <span v-if="field.required" class="text-red-500">*</span>
              </label>
              
              <!-- Select -->
              <select 
                v-if="field.field_type === 'select'"
                class="cw-input"
                :value="getFieldValue(field.field_key)"
                @change="updateCustomField(field.field_key, $event.target.value)"
              >
                <option value="">-</option>
                <option v-for="opt in field.select_options" :key="opt" :value="opt">{{ opt }}</option>
              </select>

              <!-- Textarea -->
              <textarea 
                v-else-if="field.field_type === 'textarea'"
                class="cw-input cw-textarea"
                rows="1"
                :value="getFieldValue(field.field_key)"
                @blur="updateCustomField(field.field_key, $event.target.value)"
              ></textarea>

              <!-- Checkbox -->
              <div v-else-if="field.field_type === 'checkbox'" class="flex items-center mt-1">
                 <input 
                    type="checkbox" 
                    class="cw-checkbox"
                    :checked="getFieldValue(field.field_key) === 'true'"
                    @change="updateCustomField(field.field_key, $event.target.checked ? 'true' : 'false')"
                 >
                 <span class="ml-2 text-sm text-slate-600">Sim</span>
              </div>

              <!-- Default Input -->
              <input 
                v-else
                :type="field.field_type === 'currency' ? 'number' : field.field_type"
                class="cw-input"
                :value="getFieldValue(field.field_key)"
                @blur="updateCustomField(field.field_key, $event.target.value)"
              />
           </div>
        </div>

        <!-- Footer -->
        <div class="cw-crm-footer">
           <button class="cw-btn-link text-red-500" @click="confirmRemove">
             <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mr-1"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
             Desvincular Negócio
           </button>
        </div>

      </div>
    </div>

    <!-- Modal de Perda -->
    <div v-if="showLossModal" class="cw-modal-backdrop" @click="showLossModal = false">
      <div class="cw-modal" @click.stop>
        <div class="cw-modal-header">Motivo da Perda</div>
        <div class="cw-modal-body">
           <select v-model="lossReason" class="cw-input mb-2">
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
             class="cw-input"
             placeholder="Detalhes..."
           />
        </div>
        <div class="cw-modal-footer">
           <button class="cw-btn cw-btn-secondary mr-2" @click="showLossModal = false">Cancelar</button>
           <button class="cw-btn cw-btn-danger" @click="confirmLoss" :disabled="!lossReason">Confirmar</button>
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
  name: 'ChatwootCrmSection',
  props: {
    conversationId: { type: [Number, String], required: true },
    currentStageId: { type: Number, default: null },
    initialDealValue: { type: [Number, String], default: null },
    initialClosedWon: { type: Boolean, default: null },
    initialClosedReason: { type: String, default: null },
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

    const currentPipelineStages = computed(() => currentPipeline.value?.kanban_stages || []);
    
    const currentStageName = computed(() => {
        const stage = currentPipelineStages.value.find(s => s.id === currentStageIdLocal.value);
        return stage ? stage.name : 'Desconhecido';
    });

    const availableStages = computed(() => {
      if (!selectedPipelineId.value) return [];
      const pipeline = pipelines.value.find(p => p.id === selectedPipelineId.value);
      return pipeline?.kanban_stages || [];
    });

    // Methods
    const loadData = async () => {
      isLoading.value = true;
      try {
        const pipelinesRes = await KanbanAPI.getPipelines(accountId.value);
        pipelines.value = pipelinesRes.data.filter(p => p.pipeline_type === 'conversations');

        if (props.currentStageId) {
          currentStageIdLocal.value = props.currentStageId;
          await loadCustomFields();
        }
      } catch (error) {
        console.error('Erro CRM:', error);
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
        console.error('Erro Campos:', error);
      }
    };

    const getFieldValue = (fieldKey) => customFieldValues.value[fieldKey]?.value || '';

    const addToCrm = async () => {
      if (!selectedStageId.value) return;
      isSaving.value = true;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, selectedStageId.value);
        currentStageIdLocal.value = selectedStageId.value;
        await loadCustomFields();
        emit('updated', { stageId: selectedStageId.value });
      } catch (error) { console.error('Erro Add:', error); } 
      finally { isSaving.value = false; }
    };

    const onStageChange = async () => {
      isSaving.value = true;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, currentStageIdLocal.value);
        emit('updated', { stageId: currentStageIdLocal.value });
      } catch (error) { console.error('Erro Stage:', error); } 
      finally { isSaving.value = false; }
    };

    const updateDealValue = async (value) => {
      const numValue = parseFloat(value) || null;
      if (numValue === dealValue.value) return;
      isSaving.value = true;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { deal_value: numValue });
        dealValue.value = numValue;
        emit('updated', { deal_value: numValue });
      } catch (error) { console.error('Erro Valor:', error); }
      finally { isSaving.value = false; }
    };

    const markAsWon = async () => {
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { closed_won: true });
        closedWon.value = true;
        emit('updated', { closed_won: true });
      } catch (error) { console.error('Erro Ganho:', error); }
    };

    const confirmLoss = async () => {
      const reason = lossReason.value === 'Outro' ? customLossReason.value : lossReason.value;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { closed_won: false, closed_reason: reason });
        closedWon.value = false;
        closedReason.value = reason;
        showLossModal.value = false;
        emit('updated', { closed_won: false, closed_reason: reason });
      } catch (error) { console.error('Erro Perdido:', error); }
    };

    const resetStatus = async () => {
      if (!confirm('Reabrir negócio?')) return;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, { closed_won: null, closed_reason: null });
        closedWon.value = null;
        closedReason.value = null;
        emit('updated', { closed_won: null, closed_reason: null });
      } catch (error) { console.error('Erro Reset:', error); }
    };

    const updateCustomField = async (fieldKey, value) => {
      // Otimista: atualiza localmente
      if (!customFieldValues.value[fieldKey]) customFieldValues.value[fieldKey] = {};
      customFieldValues.value[fieldKey].value = value;
      
      try {
        await KanbanAPI.bulkUpdateCustomFieldValues(accountId.value, props.conversationId, { [fieldKey]: value });
      } catch (error) { console.error('Erro Field:', error); }
    };

    const confirmRemove = async () => {
      if (!confirm('Desvincular do CRM?')) return;
      try {
        await KanbanAPI.updateConversationStage(accountId.value, props.conversationId, null);
        currentStageIdLocal.value = null;
        customFields.value = [];
        emit('updated', { stageId: null });
      } catch (error) { console.error('Erro Remove:', error); }
    };

    watch(() => props.currentStageId, (newVal) => { currentStageIdLocal.value = newVal; if (newVal) loadCustomFields(); });

    // Reset all CRM state when switching conversations
    watch(() => props.conversationId, () => {
      dealValue.value = props.initialDealValue;
      closedWon.value = props.initialClosedWon;
      closedReason.value = props.initialClosedReason;
      customFieldValues.value = {};
      selectedPipelineId.value = null;
      selectedStageId.value = null;
      currentStageIdLocal.value = props.currentStageId;
      loadData();
    });

    // Sync props when parent updates them for the new conversation
    watch(() => props.initialDealValue, (newVal) => { dealValue.value = newVal; });
    watch(() => props.initialClosedWon, (newVal) => { closedWon.value = newVal; });
    watch(() => props.initialClosedReason, (newVal) => { closedReason.value = newVal; });

    onMounted(loadData);

    return {
      isLoading, isSaving, pipelines, selectedPipelineId, selectedStageId, currentStageIdLocal,
      dealValue, closedWon, closedReason, customFields, showLossModal, lossReason, customLossReason,
      isInCrm, currentPipelineStages, availableStages, getFieldValue, addToCrm, onStageChange,
      updateDealValue, markAsWon, confirmLoss, resetStatus, updateCustomField, confirmRemove, currentStageName
    };
  }
};
</script>

<style scoped>
/* ESTILOS NATIVOS CHATWOOT - CLEAN */
.cw-crm-panel {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  color: #1f2937;
  padding: 4px;
}

.cw-crm-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e5e7eb;
}

.cw-crm-title {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
  display: flex;
  align-items: center;
}

.cw-crm-badge-saved {
    font-size: 10px;
    color: #16a34a;
    font-weight: 500;
}
.cw-crm-loading {
    font-size: 10px;
    color: #6b7280;
}

.cw-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid #e5e7eb;
  border-top-color: #1f93ff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

/* Inputs Base */
.cw-input, .cw-input-ghost {
  width: 100%;
  padding: 8px 10px;
  font-size: 13px;
  border-radius: 6px;
  outline: none;
  transition: all 0.2s;
  box-sizing: border-box; 
}

.cw-input {
  background-color: #ffffff;
  border: 1px solid #d1d5db;
  color: #374151;
  margin-bottom: 8px;
}

.cw-input:focus {
  border-color: #1f93ff;
  box-shadow: 0 0 0 1px #1f93ff;
}

.cw-input-ghost {
  background: transparent;
  border: 1px solid transparent;
  color: #4b5563;
  padding: 4px 0;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
}

.cw-input-ghost:hover {
  color: #1f93ff;
}

/* Card Highlight (Valor) */
.cw-card-highlight {
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
}

.cw-value-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}

.cw-currency-symbol {
  font-size: 14px;
  font-weight: 500;
  color: #6b7280;
  margin-right: 4px;
}

.cw-input-value {
  width: 100%;
  background: transparent;
  border: none;
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  outline: none;
  padding: 0;
}

.cw-input-value::placeholder { color: #d1d5db; }
.cw-input-value:focus { color: #1f93ff; }
.cw-input-value:disabled { color: #9ca3af; }

/* Status Bar */
.cw-status-bar {
  margin-bottom: 16px;
}

.cw-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 500;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid transparent;
  width: 100%;
  gap: 6px;
}

.cw-btn-primary { background: #1f93ff; color: white; }
.cw-btn-primary:hover { background: #1a7ecb; }
.cw-btn-primary:disabled { opacity: 0.6; cursor: not-allowed; }

.cw-btn-outline-success {
  background: #f0fdf4; border-color: #bbf7d0; color: #16a34a;
}
.cw-btn-outline-success:hover { background: #dcfce7; }

.cw-btn-outline-danger {
  background: #fef2f2; border-color: #fecaca; color: #dc2626;
}
.cw-btn-outline-danger:hover { background: #fee2e2; }

.cw-btn-icon {
  padding: 6px;
  color: #6b7280;
  border-radius: 4px;
  background: transparent;
  border: none;
  cursor: pointer;
}
.cw-btn-icon:hover { background: #e5e7eb; color: #1f2937; }

.cw-badge {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 4px;
  display: inline-block;
}
.cw-badge-won { background: #dcfce7; color: #15803d; }
.cw-badge-lost { background: #fee2e2; color: #b91c1c; }

/* Fields List */
.cw-fields-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.cw-field-group {
  display: flex;
  flex-direction: column;
}

.cw-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  color: #6b7280;
  margin-bottom: 4px;
  letter-spacing: 0.02em;
}

.cw-textarea { resize: vertical; min-height: 60px; font-family: inherit; }
.cw-checkbox { width: 14px; height: 14px; margin-right: 8px; }

/* Footer */
.cw-crm-footer {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #f3f4f6;
  text-align: center;
}

.cw-btn-link {
  background: none;
  border: none;
  font-size: 12px;
  cursor: pointer;
  text-decoration: none;
  color: #ef4444;
  opacity: 0.8;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  width: 100%;
}
.cw-btn-link:hover { opacity: 1; background: #fef2f2; padding: 4px; border-radius: 4px; }

/* Modal */
.cw-modal-backdrop {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center;
  z-index: 9999;
}

.cw-modal {
  background: white;
  width: 90%; max-width: 320px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  overflow: hidden;
}

.cw-modal-header {
  padding: 12px 16px;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
  font-weight: 600;
  color: #111827;
  font-size: 13px;
}

.cw-modal-body { padding: 16px; }

.cw-modal-footer {
  padding: 12px 16px;
  display: flex; justify-content: flex-end;
  background: #f9fafb;
  border-top: 1px solid #e5e7eb;
  gap: 8px;
}

.cw-btn-secondary { background: white; border: 1px solid #d1d5db; color: #374151; padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; }
.cw-btn-danger { background: #dc2626; color: white; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; }
.cw-btn-danger:disabled { opacity: 0.5; cursor: not-allowed; }

/* Dark Mode Support (Chatwoot Auto) */
@media (prefers-color-scheme: dark) {
  .cw-crm-panel { color: #e5e7eb; }
  .cw-crm-header { border-color: #374151; }
  .cw-crm-title { color: #f9fafb; }
  .cw-input { background: #1f2937; border-color: #374151; color: #f3f4f6; }
  .cw-card-highlight { background: #1f2937; border-color: #374151; }
  .cw-input-value { color: #f9fafb; }
  .cw-input-ghost { color: #9ca3af; }
  .cw-btn-secondary { background: #1f2937; border-color: #374151; color: #e5e7eb; }
  .cw-modal { background: #111827; border: 1px solid #374151; }
  .cw-modal-header, .cw-modal-footer { background: #1f2937; border-color: #374151; color: #f3f4f6; }
  .cw-btn-outline-success { background: rgba(22, 163, 74, 0.1); border-color: rgba(22, 163, 74, 0.3); color: #4ade80; }
  .cw-btn-outline-danger { background: rgba(220, 38, 38, 0.1); border-color: rgba(220, 38, 38, 0.3); color: #f87171; }
  .cw-crm-footer { border-color: #374151; }
}
</style>
