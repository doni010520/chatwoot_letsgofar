<template>
  <div class="crm-fields">
    <!-- Valor do Negócio -->
    <div class="crm-fields__field">
      <label>Valor do Negócio</label>
      <div class="crm-fields__input-group">
        <span class="crm-fields__currency">R$</span>
        <input
          v-model="dealValue"
          type="number"
          step="0.01"
          min="0"
          placeholder="0,00"
          class="crm-fields__input"
          @blur="saveDealValue"
        />
      </div>
    </div>

    <!-- Botões Ganho/Perdido -->
    <div v-if="closedWon === null" class="crm-fields__actions">
      <button class="crm-fields__btn crm-fields__btn--won" @click="markAsWon">
        ✓ Ganho
      </button>
      <button class="crm-fields__btn crm-fields__btn--lost" @click="openLostModal">
        ✗ Perdido
      </button>
    </div>

    <!-- Status Ganho -->
    <div v-else-if="closedWon === true" class="crm-fields__status crm-fields__status--won">
      <span>✓ Marcado como Ganho</span>
      <button class="crm-fields__undo" @click="undoClose">Desfazer</button>
    </div>

    <!-- Status Perdido -->
    <div v-else class="crm-fields__status crm-fields__status--lost">
      <span>✗ Perdido: {{ closedReason || 'Sem motivo' }}</span>
      <button class="crm-fields__undo" @click="undoClose">Desfazer</button>
    </div>

    <!-- Modal Motivo de Perda -->
    <div v-if="showLostModal" class="crm-modal-overlay" @click.self="closeLostModal">
      <div class="crm-modal">
        <h3>Motivo da Perda</h3>
        <div class="crm-modal__options">
          <button
            v-for="reason in lossReasons"
            :key="reason"
            class="crm-modal__option"
            @click="markAsLost(reason)"
          >
            {{ reason }}
          </button>
        </div>
        <div class="crm-modal__custom">
          <input
            v-model="customReason"
            type="text"
            placeholder="Outro motivo..."
            @keyup.enter="markAsLost(customReason)"
          />
          <button @click="markAsLost(customReason)" :disabled="!customReason">
            Confirmar
          </button>
        </div>
        <button class="crm-modal__cancel" @click="closeLostModal">Cancelar</button>
      </div>
    </div>

    <div v-if="isSaving" class="crm-fields__saving">Salvando...</div>
  </div>
</template>

<script>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanCrmFields',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
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
    const dealValue = ref(props.initialDealValue || '');
    const closedWon = ref(props.initialClosedWon);
    const closedReason = ref(props.initialClosedReason);
    const showLostModal = ref(false);
    const customReason = ref('');
    const isSaving = ref(false);

    const lossReasons = [
      'Preço',
      'Concorrência',
      'Sem resposta',
      'Desistiu',
      'Não qualificado',
      'Timing ruim',
    ];

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const saveDealValue = async () => {
      if (!dealValue.value && dealValue.value !== 0) return;
      await saveFields({ deal_value: parseFloat(dealValue.value) || null });
    };

    const markAsWon = async () => {
      await saveFields({
        closed_won: true,
        closed_at: new Date().toISOString(),
        closed_reason: null,
      });
      closedWon.value = true;
      closedReason.value = null;
    };

    const markAsLost = async (reason) => {
      if (!reason) return;
      await saveFields({
        closed_won: false,
        closed_at: new Date().toISOString(),
        closed_reason: reason,
      });
      closedWon.value = false;
      closedReason.value = reason;
      closeLostModal();
    };

    const undoClose = async () => {
      await saveFields({
        closed_won: null,
        closed_at: null,
        closed_reason: null,
      });
      closedWon.value = null;
      closedReason.value = null;
    };

    const saveFields = async (fields) => {
      isSaving.value = true;
      try {
        await KanbanAPI.updateCrmFields(accountId.value, props.conversationId, fields);
        emit('updated', fields);
      } catch (error) {
        console.error('Erro ao salvar campos CRM:', error);
      } finally {
        isSaving.value = false;
      }
    };

    const openLostModal = () => {
      showLostModal.value = true;
      customReason.value = '';
    };

    const closeLostModal = () => {
      showLostModal.value = false;
      customReason.value = '';
    };

    watch(() => props.initialDealValue, (val) => {
      dealValue.value = val || '';
    });

    watch(() => props.initialClosedWon, (val) => {
      closedWon.value = val;
    });

    watch(() => props.initialClosedReason, (val) => {
      closedReason.value = val;
    });

    return {
      dealValue,
      closedWon,
      closedReason,
      showLostModal,
      customReason,
      isSaving,
      lossReasons,
      saveDealValue,
      markAsWon,
      markAsLost,
      undoClose,
      openLostModal,
      closeLostModal,
    };
  },
};
</script>

<style scoped>
.crm-fields {
  padding: 8px 0;
}

.crm-fields__field {
  margin-bottom: 12px;
}

.crm-fields__field label {
  display: block;
  font-size: 12px;
  font-weight: 500;
  color: var(--s-600);
  margin-bottom: 4px;
}

.crm-fields__input-group {
  display: flex;
  align-items: center;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  overflow: hidden;
}

.crm-fields__currency {
  padding: 8px 10px;
  background-color: var(--s-50);
  color: var(--s-600);
  font-size: 13px;
}

.crm-fields__input {
  flex: 1;
  padding: 8px 10px;
  border: none;
  font-size: 13px;
  color: var(--s-800);
}

.crm-fields__input:focus {
  outline: none;
}

.crm-fields__actions {
  display: flex;
  gap: 8px;
}

.crm-fields__btn {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.crm-fields__btn--won {
  background-color: #d1fae5;
  color: #065f46;
}

.crm-fields__btn--won:hover {
  background-color: #a7f3d0;
}

.crm-fields__btn--lost {
  background-color: #fee2e2;
  color: #991b1b;
}

.crm-fields__btn--lost:hover {
  background-color: #fecaca;
}

.crm-fields__status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
}

.crm-fields__status--won {
  background-color: #d1fae5;
  color: #065f46;
}

.crm-fields__status--lost {
  background-color: #fee2e2;
  color: #991b1b;
}

.crm-fields__undo {
  background: none;
  border: none;
  font-size: 11px;
  color: inherit;
  cursor: pointer;
  opacity: 0.7;
  text-decoration: underline;
}

.crm-fields__undo:hover {
  opacity: 1;
}

.crm-fields__saving {
  font-size: 11px;
  color: var(--s-500);
  text-align: center;
  margin-top: 8px;
}

/* Modal */
.crm-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
}

.crm-modal {
  background-color: #1f2937;
  border-radius: 12px;
  padding: 20px;
  width: 320px;
  max-width: 90vw;
}

.crm-modal h3 {
  color: #f9fafb;
  font-size: 16px;
  margin: 0 0 16px 0;
}

.crm-modal__options {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}

.crm-modal__option {
  padding: 10px 12px;
  background-color: #374151;
  border: 1px solid #4b5563;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 13px;
  cursor: pointer;
  text-align: left;
  transition: all 0.2s;
}

.crm-modal__option:hover {
  background-color: #4b5563;
  border-color: #6b7280;
}

.crm-modal__custom {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.crm-modal__custom input {
  flex: 1;
  padding: 8px 12px;
  background-color: #111827;
  border: 1px solid #374151;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 13px;
}

.crm-modal__custom input:focus {
  outline: none;
  border-color: #3b82f6;
}

.crm-modal__custom button {
  padding: 8px 12px;
  background-color: #3b82f6;
  border: none;
  border-radius: 6px;
  color: white;
  font-size: 13px;
  cursor: pointer;
}

.crm-modal__custom button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.crm-modal__cancel {
  width: 100%;
  padding: 8px;
  background: none;
  border: 1px solid #4b5563;
  border-radius: 6px;
  color: #9ca3af;
  font-size: 13px;
  cursor: pointer;
}

.crm-modal__cancel:hover {
  background-color: #374151;
}
</style>
