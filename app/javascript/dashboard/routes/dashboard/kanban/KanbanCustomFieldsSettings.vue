<template>
  <div class="custom-fields-settings">
    <div class="settings-header">
      <h3 class="settings-header__title">Campos Personalizados</h3>
      <button class="btn-add" @click="showAddModal = true">
        + Novo Campo
      </button>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="settings-loading">Carregando...</div>

    <!-- Empty State -->
    <div v-else-if="fields.length === 0" class="settings-empty">
      <p>Nenhum campo personalizado criado.</p>
      <p class="settings-empty__hint">Crie campos para coletar informações específicas dos leads.</p>
    </div>

    <!-- Fields List -->
    <div v-else class="fields-table">
      <div class="fields-table__header">
        <span>Nome</span>
        <span>Tipo</span>
        <span>No Card</span>
        <span>Ações</span>
      </div>
      <div
        v-for="field in fields"
        :key="field.id"
        class="fields-table__row"
      >
        <span class="fields-table__name">
          {{ field.name }}
          <span v-if="field.required" class="fields-table__required">*</span>
        </span>
        <span class="fields-table__type">{{ getTypeLabel(field.field_type) }}</span>
        <span class="fields-table__card">
          <span v-if="field.show_on_card" class="badge badge--green">Sim</span>
          <span v-else class="badge badge--gray">Não</span>
        </span>
        <span class="fields-table__actions">
          <button class="btn-icon" @click="editField(field)" title="Editar">✏️</button>
          <button class="btn-icon btn-icon--danger" @click="confirmDelete(field)" title="Excluir">🗑️</button>
        </span>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <div v-if="showAddModal || editingField" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal__header">
          <h4>{{ editingField ? 'Editar Campo' : 'Novo Campo' }}</h4>
          <button class="modal__close" @click="closeModal">✕</button>
        </div>

        <div class="modal__body">
          <div class="form-group">
            <label>Nome do Campo *</label>
            <input
              v-model="formData.name"
              type="text"
              placeholder="Ex: kWp Estimado"
              class="form-input"
            />
          </div>

          <div class="form-group">
            <label>Tipo *</label>
            <select v-model="formData.field_type" class="form-input">
              <option value="text">Texto</option>
              <option value="textarea">Texto Longo</option>
              <option value="number">Número</option>
              <option value="currency">Moeda (R$)</option>
              <option value="select">Lista de Opções</option>
              <option value="multiselect">Múltipla Escolha</option>
              <option value="date">Data</option>
              <option value="checkbox">Sim/Não</option>
            </select>
          </div>

          <!-- Options for Select/Multiselect -->
          <div v-if="formData.field_type === 'select' || formData.field_type === 'multiselect'" class="form-group">
            <label>Opções (uma por linha)</label>
            <textarea
              v-model="optionsText"
              class="form-input"
              rows="4"
              placeholder="Opção 1&#10;Opção 2&#10;Opção 3"
            />
          </div>

          <div class="form-group">
            <label>Descrição (opcional)</label>
            <input
              v-model="formData.description"
              type="text"
              placeholder="Ajuda para preencher o campo"
              class="form-input"
            />
          </div>

          <div class="form-row">
            <label class="form-checkbox">
              <input v-model="formData.required" type="checkbox" />
              Campo obrigatório
            </label>

            <label class="form-checkbox">
              <input v-model="formData.show_on_card" type="checkbox" />
              Mostrar no card do Kanban
            </label>
          </div>
        </div>

        <div class="modal__footer">
          <button class="btn-cancel" @click="closeModal">Cancelar</button>
          <button class="btn-save" @click="saveField" :disabled="!formData.name">
            {{ editingField ? 'Salvar' : 'Criar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation -->
    <div v-if="deletingField" class="modal-overlay" @click.self="deletingField = null">
      <div class="modal modal--small">
        <div class="modal__header">
          <h4>Confirmar Exclusão</h4>
        </div>
        <div class="modal__body">
          <p>Tem certeza que deseja excluir o campo <strong>{{ deletingField.name }}</strong>?</p>
          <p class="text-danger">Os valores salvos neste campo serão perdidos.</p>
        </div>
        <div class="modal__footer">
          <button class="btn-cancel" @click="deletingField = null">Cancelar</button>
          <button class="btn-danger" @click="deleteField">Excluir</button>
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
  name: 'KanbanCustomFieldsSettings',
  props: {
    pipelineId: {
      type: [Number, String],
      required: true,
    },
  },
  emits: ['updated'],
  setup(props, { emit }) {
    const store = useStore();
    const isLoading = ref(false);
    const fields = ref([]);
    const showAddModal = ref(false);
    const editingField = ref(null);
    const deletingField = ref(null);
    const optionsText = ref('');

    const formData = ref({
      name: '',
      field_type: 'text',
      description: '',
      required: false,
      show_on_card: false,
    });

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const loadFields = async () => {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getCustomFields(accountId.value, props.pipelineId);
        fields.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar campos:', error);
      } finally {
        isLoading.value = false;
      }
    };

    const getTypeLabel = (type) => {
      const labels = {
        text: 'Texto',
        textarea: 'Texto Longo',
        number: 'Número',
        currency: 'Moeda',
        select: 'Lista',
        multiselect: 'Múltipla',
        date: 'Data',
        checkbox: 'Sim/Não',
      };
      return labels[type] || type;
    };

    const resetForm = () => {
      formData.value = {
        name: '',
        field_type: 'text',
        description: '',
        required: false,
        show_on_card: false,
      };
      optionsText.value = '';
    };

    const editField = (field) => {
      editingField.value = field;
      formData.value = {
        name: field.name,
        field_type: field.field_type,
        description: field.description || '',
        required: field.required,
        show_on_card: field.show_on_card,
      };
      optionsText.value = (field.select_options || []).join('\n');
    };

    const closeModal = () => {
      showAddModal.value = false;
      editingField.value = null;
      resetForm();
    };

    const saveField = async () => {
      if (!formData.value.name) return;

      const data = { ...formData.value };
      
      // Parse options for select/multiselect
      if (data.field_type === 'select' || data.field_type === 'multiselect') {
        data.select_options = optionsText.value
          .split('\n')
          .map(s => s.trim())
          .filter(s => s.length > 0);
      }

      try {
        if (editingField.value) {
          await KanbanAPI.updateCustomField(accountId.value, props.pipelineId, editingField.value.id, data);
        } else {
          await KanbanAPI.createCustomField(accountId.value, props.pipelineId, data);
        }
        await loadFields();
        emit('updated');
        closeModal();
      } catch (error) {
        console.error('Erro ao salvar campo:', error);
      }
    };

    const confirmDelete = (field) => {
      deletingField.value = field;
    };

    const deleteField = async () => {
      if (!deletingField.value) return;

      try {
        await KanbanAPI.deleteCustomField(accountId.value, props.pipelineId, deletingField.value.id);
        await loadFields();
        emit('updated');
        deletingField.value = null;
      } catch (error) {
        console.error('Erro ao excluir campo:', error);
      }
    };

    watch(() => props.pipelineId, () => {
      loadFields();
    });

    onMounted(() => {
      loadFields();
    });

    return {
      isLoading,
      fields,
      showAddModal,
      editingField,
      deletingField,
      formData,
      optionsText,
      getTypeLabel,
      editField,
      closeModal,
      saveField,
      confirmDelete,
      deleteField,
    };
  },
};
</script>

<style scoped>
.custom-fields-settings {
  padding: 16px 0;
}

.settings-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.settings-header__title {
  font-size: 16px;
  font-weight: 600;
  color: #f3f4f6;
  margin: 0;
}

.btn-add {
  padding: 8px 16px;
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-add:hover {
  background-color: #2563eb;
}

.settings-loading,
.settings-empty {
  text-align: center;
  padding: 32px;
  color: #9ca3af;
}

.settings-empty__hint {
  font-size: 13px;
  margin-top: 8px;
}

/* Table */
.fields-table {
  border: 1px solid #374151;
  border-radius: 8px;
  overflow: hidden;
}

.fields-table__header {
  display: grid;
  grid-template-columns: 2fr 1fr 80px 80px;
  gap: 12px;
  padding: 12px 16px;
  background-color: #1f2937;
  font-size: 12px;
  font-weight: 600;
  color: #9ca3af;
  text-transform: uppercase;
}

.fields-table__row {
  display: grid;
  grid-template-columns: 2fr 1fr 80px 80px;
  gap: 12px;
  padding: 12px 16px;
  border-top: 1px solid #374151;
  align-items: center;
  font-size: 14px;
  color: #f3f4f6;
}

.fields-table__row:hover {
  background-color: #1f2937;
}

.fields-table__required {
  color: #ef4444;
}

.fields-table__type {
  color: #9ca3af;
}

.badge {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
}

.badge--green {
  background-color: #065f46;
  color: #10b981;
}

.badge--gray {
  background-color: #374151;
  color: #9ca3af;
}

.btn-icon {
  padding: 4px 8px;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.btn-icon:hover {
  opacity: 1;
}

.btn-icon--danger:hover {
  opacity: 1;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background-color: #1f2937;
  border-radius: 12px;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal--small {
  max-width: 400px;
}

.modal__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #374151;
}

.modal__header h4 {
  margin: 0;
  font-size: 16px;
  color: #f3f4f6;
}

.modal__close {
  background: none;
  border: none;
  color: #9ca3af;
  font-size: 18px;
  cursor: pointer;
}

.modal__body {
  padding: 20px;
}

.modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 20px;
  border-top: 1px solid #374151;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #d1d5db;
  margin-bottom: 6px;
}

.form-input {
  width: 100%;
  padding: 10px 12px;
  background-color: #111827;
  border: 1px solid #374151;
  border-radius: 6px;
  color: #f3f4f6;
  font-size: 14px;
}

.form-input:focus {
  outline: none;
  border-color: #3b82f6;
}

textarea.form-input {
  resize: vertical;
  min-height: 80px;
}

.form-row {
  display: flex;
  gap: 24px;
}

.form-checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #d1d5db;
  cursor: pointer;
}

.btn-cancel {
  padding: 8px 16px;
  background-color: transparent;
  border: 1px solid #374151;
  border-radius: 6px;
  color: #d1d5db;
  font-size: 13px;
  cursor: pointer;
}

.btn-save {
  padding: 8px 16px;
  background
