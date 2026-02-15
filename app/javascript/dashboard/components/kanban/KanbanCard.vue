<template>
  <div 
    class="kanban-card" 
    :class="[cardClasses, { 'kanban-card--dragging': isDragging }]"
    draggable="true"
    @click="$emit('click')"
    @dragstart="onDragStart"
    @dragend="onDragEnd"
  >
    <!-- Header com foto e info do contato -->
    <div class="kanban-card__header">
      <div class="kanban-card__avatar">
        <img
          v-if="contactThumbnail"
          :src="contactThumbnail"
          :alt="contactName"
          class="kanban-card__avatar-img"
        />
        <span v-else class="kanban-card__avatar-initials">
          {{ getInitials(contactName) }}
        </span>
      </div>
      <div class="kanban-card__info">
        <span class="kanban-card__name">{{ contactName }}</span>
        <span class="kanban-card__phone">{{ contactPhone }}</span>
      </div>
    </div>

    <!-- Valor do negócio -->
    <div v-if="item.deal_value" class="kanban-card__value">
      {{ formatCurrency(item.deal_value) }}
    </div>

    <!-- Campos Personalizados -->
    <div v-if="visibleCustomFields.length > 0" class="kanban-card__custom-fields">
      <div
        v-for="field in visibleCustomFields"
        :key="field.field_key"
        class="kanban-card__custom-field"
      >
        <span class="kanban-card__custom-field-label">{{ field.name }}:</span>
        <span class="kanban-card__custom-field-value">{{ formatFieldValue(field) }}</span>
      </div>
    </div>

    <!-- ID da conversa -->
    <div v-if="itemType === 'conversation'" class="kanban-card__id">
      #{{ item.display_id }}
    </div>

    <!-- Status e tempo -->
    <div class="kanban-card__footer">
      <span
        class="kanban-card__status"
        :class="`kanban-card__status--${item.status}`"
      >
        {{ statusLabel }}
      </span>
      <span v-if="timeAgo" class="kanban-card__time">
        {{ timeAgo }}
      </span>
    </div>

    <!-- Resultado (Ganho/Perdido) - Se já foi marcado -->
    <div v-if="item.closed_won !== null && item.closed_won !== undefined" class="kanban-card__result" :class="resultClass">
      {{ item.closed_won ? '✓ Ganho' : '✗ Perdido' }}
      <span v-if="!item.closed_won && item.closed_reason" class="kanban-card__reason">
        - {{ item.closed_reason }}
      </span>
    </div>

    <!-- Botões Ganho/Perdido - Se ainda não foi marcado -->
    <div v-else class="kanban-card__actions">
      <button 
        class="kanban-card__action-btn kanban-card__action-btn--won"
        title="Marcar como Ganho"
        @click.stop="markAsWon"
      >
        ✓ Ganho
      </button>
      <button 
        class="kanban-card__action-btn kanban-card__action-btn--lost"
        title="Marcar como Perdido"
        @click.stop="markAsLost"
      >
        ✗ Perdido
      </button>
    </div>

    <!-- Tarefas -->
    <div v-if="hasTasks" class="kanban-card__tasks">
      <span class="kanban-card__tasks-icon">📋</span>
      <span class="kanban-card__tasks-count">{{ item.tasks.pending }}</span>
      <span v-if="item.tasks.overdue > 0" class="kanban-card__tasks-overdue">
        ({{ item.tasks.overdue }} atrasada{{ item.tasks.overdue > 1 ? 's' : '' }})
      </span>
    </div>

    <!-- Assignee -->
    <div v-if="item.assignee" class="kanban-card__assignee">
      <span class="kanban-card__assignee-label">Atribuído:</span>
      <span class="kanban-card__assignee-name">{{ item.assignee.name }}</span>
    </div>

    <!-- Modal de Motivo de Perda -->
    <div v-if="showLossReasonModal" class="kanban-card__modal-overlay" @click.stop="closeLossModal">
      <div class="kanban-card__modal" @click.stop>
        <h4>Motivo da Perda</h4>
        <select v-model="selectedLossReason" class="kanban-card__modal-select">
          <option value="">Selecione...</option>
          <option value="Preço">Preço</option>
          <option value="Concorrência">Concorrência</option>
          <option value="Timing">Timing / Não é o momento</option>
          <option value="Sem resposta">Sem resposta</option>
          <option value="Desistiu">Desistiu</option>
          <option value="Outro">Outro</option>
        </select>
        <input
          v-if="selectedLossReason === 'Outro'"
          v-model="customLossReason"
          type="text"
          placeholder="Especifique o motivo..."
          class="kanban-card__modal-input"
        />
        <div class="kanban-card__modal-actions">
          <button class="kanban-card__modal-btn kanban-card__modal-btn--cancel" @click.stop="closeLossModal">
            Cancelar
          </button>
          <button 
            class="kanban-card__modal-btn kanban-card__modal-btn--confirm" 
            :disabled="!canConfirmLoss"
            @click.stop="confirmLoss"
          >
            Confirmar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanCard',
  props: {
    item: {
      type: Object,
      required: true,
    },
    itemType: {
      type: String,
      default: 'conversation',
    },
    customFieldsConfig: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['click', 'dragstart', 'mark-won', 'mark-lost'],
  data() {
    return {
      isDragging: false,
      showLossReasonModal: false,
      selectedLossReason: '',
      customLossReason: '',
    };
  },
  computed: {
    contactName() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.name || 'Sem nome';
      }
      return this.item.name || 'Sem nome';
    },
    contactPhone() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.phone_number || this.item.contact?.email || '';
      }
      return this.item.phone_number || this.item.email || '';
    },
    contactThumbnail() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.thumbnail || this.item.contact?.avatar_url || null;
      }
      return this.item.thumbnail || this.item.avatar_url || null;
    },
    statusLabel() {
      const statuses = {
        open: 'Aberto',
        resolved: 'Resolvido',
        pending: 'Pendente',
        snoozed: 'Adiado',
      };
      return statuses[this.item.status] || this.item.status;
    },
    timeAgo() {
      const date = this.item.last_activity_at;
      if (!date) return null;
      
      const now = new Date();
      const past = new Date(date);
      const diffMs = now - past;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return 'Agora';
      if (diffMins < 60) return `${diffMins}min`;
      if (diffHours < 24) return `${diffHours}h`;
      if (diffDays < 7) return `${diffDays}d`;
      return past.toLocaleDateString('pt-BR');
    },
    cardClasses() {
      return {
        'kanban-card--won': this.item.closed_won === true,
        'kanban-card--lost': this.item.closed_won === false,
      };
    },
    resultClass() {
      return this.item.closed_won ? 'kanban-card__result--won' : 'kanban-card__result--lost';
    },
    hasTasks() {
      return this.item.tasks && this.item.tasks.pending > 0;
    },
    visibleCustomFields() {
      if (!this.item.custom_fields || !this.customFieldsConfig) return [];
      
      return this.customFieldsConfig
        .filter(field => field.show_on_card && this.item.custom_fields[field.field_key])
        .map(field => ({
          ...field,
          value: this.item.custom_fields[field.field_key],
        }));
    },
    canConfirmLoss() {
      if (!this.selectedLossReason) return false;
      if (this.selectedLossReason === 'Outro' && !this.customLossReason.trim()) return false;
      return true;
    },
  },
  methods: {
    onDragStart(event) {
      this.isDragging = true;
      this.$emit('dragstart', event);
    },
    onDragEnd() {
      this.isDragging = false;
    },
    getInitials(name) {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .substring(0, 2)
        .toUpperCase();
    },
    formatCurrency(value) {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      }).format(value);
    },
    formatFieldValue(field) {
      const value = field.value;
      if (!value) return '-';

      switch (field.field_type) {
        case 'currency':
          return this.formatCurrency(parseFloat(value) || 0);
        case 'checkbox':
          return value === 'true' ? 'Sim' : 'Não';
        case 'date':
          return new Date(value).toLocaleDateString('pt-BR');
        case 'multiselect':
          try {
            const arr = JSON.parse(value);
            return Array.isArray(arr) ? arr.join(', ') : value;
          } catch {
            return value;
          }
        default:
          return value;
      }
    },
    markAsWon() {
      this.$emit('mark-won', { itemId: this.item.id, itemType: this.itemType });
    },
    markAsLost() {
      this.showLossReasonModal = true;
    },
    closeLossModal() {
      this.showLossReasonModal = false;
      this.selectedLossReason = '';
      this.customLossReason = '';
    },
    confirmLoss() {
      const reason = this.selectedLossReason === 'Outro' 
        ? this.customLossReason.trim() 
        : this.selectedLossReason;
      
      this.$emit('mark-lost', { 
        itemId: this.item.id, 
        itemType: this.itemType,
        reason: reason
      });
      this.closeLossModal();
    },
  },
};
</script>

<style scoped>
.kanban-card {
  background-color: #ffffff;
  border-radius: 8px;
  padding: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e7eb;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
  position: relative;
}

.kanban-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  border-color: #3b82f6;
  transform: translateY(-1px);
}

.kanban-card--dragging {
  cursor: grabbing;
  transform: rotate(2deg) scale(1.02);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
  z-index: 100;
  opacity: 0.9;
}

.kanban-card--won {
  border-left: 3px solid #10b981;
}

.kanban-card--lost {
  border-left: 3px solid #ef4444;
  opacity: 0.7;
}

.kanban-card__header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.kanban-card__avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  flex-shrink: 0;
  overflow: hidden;
  background-color: #3b82f6;
  display: flex;
  align-items: center;
  justify-content: center;
}

.kanban-card__avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.kanban-card__avatar-initials {
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
}

.kanban-card__info {
  flex: 1;
  min-width: 0;
}

.kanban-card__name {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.kanban-card__phone {
  display: block;
  font-size: 12px;
  color: #6b7280;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-top: 2px;
}

.kanban-card__value {
  font-size: 16px;
  font-weight: 700;
  color: #059669;
  margin-bottom: 8px;
  padding: 4px 8px;
  background-color: #d1fae5;
  border-radius: 4px;
  display: inline-block;
}

/* Campos Personalizados */
.kanban-card__custom-fields {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 8px;
  padding: 6px 8px;
  background-color: #f9fafb;
  border-radius: 4px;
  border: 1px solid #e5e7eb;
}

.kanban-card__custom-field {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
}

.kanban-card__custom-field-label {
  color: #6b7280;
  flex-shrink: 0;
}

.kanban-card__custom-field-value {
  color: #1f2937;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.kanban-card__id {
  font-size: 11px;
  color: #9ca3af;
  margin-bottom: 8px;
}

.kanban-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.kanban-card__status {
  font-size: 11px;
  font-weight: 500;
  padding: 3px 8px;
  border-radius: 4px;
}

.kanban-card__status--open {
  background-color: #d1fae5;
  color: #065f46;
}

.kanban-card__status--pending {
  background-color: #fef3c7;
  color: #92400e;
}

.kanban-card__status--resolved {
  background-color: #e5e7eb;
  color: #4b5563;
}

.kanban-card__status--snoozed {
  background-color: #dbeafe;
  color: #1e40af;
}

.kanban-card__time {
  font-size: 11px;
  color: #9ca3af;
}

.kanban-card__result {
  font-size: 11px;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 4px;
  margin-bottom: 6px;
}

.kanban-card__result--won {
  background-color: #d1fae5;
  color: #065f46;
}

.kanban-card__result--lost {
  background-color: #fee2e2;
  color: #991b1b;
}

.kanban-card__reason {
  font-weight: 400;
}

/* Botões de Ação Ganho/Perdido */
.kanban-card__actions {
  display: flex;
  gap: 6px;
  margin-bottom: 6px;
}

.kanban-card__action-btn {
  flex: 1;
  padding: 6px 8px;
  border: none;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.kanban-card__action-btn--won {
  background-color: #d1fae5;
  color: #065f46;
}

.kanban-card__action-btn--won:hover {
  background-color: #10b981;
  color: white;
}

.kanban-card__action-btn--lost {
  background-color: #fee2e2;
  color: #991b1b;
}

.kanban-card__action-btn--lost:hover {
  background-color: #ef4444;
  color: white;
}

/* Modal de Motivo de Perda */
.kanban-card__modal-overlay {
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

.kanban-card__modal {
  background: white;
  border-radius: 8px;
  padding: 20px;
  min-width: 300px;
  max-width: 400px;
}

.kanban-card__modal h4 {
  margin: 0 0 16px 0;
  font-size: 16px;
  color: #1f2937;
}

.kanban-card__modal-select,
.kanban-card__modal-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 14px;
  margin-bottom: 12px;
}

.kanban-card__modal-select:focus,
.kanban-card__modal-input:focus {
  outline: none;
  border-color: #3b82f6;
}

.kanban-card__modal-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.kanban-card__modal-btn {
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.kanban-card__modal-btn--cancel {
  background: white;
  border: 1px solid #e5e7eb;
  color: #6b7280;
}

.kanban-card__modal-btn--cancel:hover {
  background: #f3f4f6;
}

.kanban-card__modal-btn--confirm {
  background: #ef4444;
  border: none;
  color: white;
}

.kanban-card__modal-btn--confirm:hover {
  background: #dc2626;
}

.kanban-card__modal-btn--confirm:disabled {
  background: #fca5a5;
  cursor: not-allowed;
}

/* Tarefas */
.kanban-card__tasks {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #6b7280;
  margin-bottom: 6px;
  padding: 4px 8px;
  background-color: #f3f4f6;
  border-radius: 4px;
}

.kanban-card__tasks-icon {
  font-size: 12px;
}

.kanban-card__tasks-count {
  font-weight: 600;
  color: #374151;
}

.kanban-card__tasks-overdue {
  color: #ef4444;
  font-weight: 500;
}

.kanban-card__assignee {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #6b7280;
  padding-top: 6px;
  border-top: 1px solid #f3f4f6;
}

.kanban-card__assignee-label {
  color: #9ca3af;
}

.kanban-card__assignee-name {
  color: #4b5563;
  font-weight: 500;
}

/* Dark mode support */
.dark .kanban-card {
  background-color: #1f2937;
  border-color: #374151;
}

.dark .kanban-card__name {
  color: #f9fafb;
}

.dark .kanban-card__phone {
  color: #9ca3af;
}

.dark .kanban-card__custom-fields {
  background-color: #374151;
  border-color: #4b5563;
}

.dark .kanban-card__custom-field-value {
  color: #f9fafb;
}

.dark .kanban-card__modal {
  background-color: #1f2937;
}

.dark .kanban-card__modal h4 {
  color: #f9fafb;
}

.dark .kanban-card__modal-select,
.dark .kanban-card__modal-input {
  background-color: #374151;
  border-color: #4b5563;
  color: #f9fafb;
}
</style>
