<template>
  <div class="custom-fields-manager">
    <div class="manager-header">
      <h3 class="manager-header__title">Campos Personalizados</h3>
      <button class="btn-add" @click="showForm = true" v-if="!showForm">
        + Novo Campo
      </button>
    </div>

    <!-- Form -->
    <div v-if="showForm" class="field-form">
      <div class="field-form__row">
        <div class="field-form__group">
          <label>Nome do Campo *</label>
          <input v-model="newField.name" type="text" placeholder="Ex: kWp estimado" />
        </div>
        <div class="field-form__group">
          <label>Tipo *</label>
          <select v-model="newField.field_type">
            <option value="text">Texto</option>
            <option value="textarea">Texto Longo</option>
            <option value="number">Número</option>
            <option value="currency">Moeda (R$)</option>
            <option value="select">Dropdown</option>
            <option value="multiselect">Múltipla Escolha</option>
            <option value="date">Data</option>
            <option value="checkbox">Sim/Não</option>
          </select>
        </div>
      </div>

      <div class="field-form__group">
        <label>Descrição (opcional)</label>
        <input v-model="newField.description" type="text" placeholder="Ajuda para o usuário" />
      </div>

      <!-- Opções para Select/Multiselect -->
      <div v-if="['select', 'multiselect'].includes(newField.field_type)" class="field-form__group">
        <label>Opções (uma por linha) *</label>
        <textarea
          v-model="optionsText"
          rows="4"
          placeholder="Opção 1&#10;Opção 2&#10;Opção 3"
        />
      </div>

      <div class="field-form__row">
        <label class="field-form__checkbox">
          <input type="checkbox" v-model="newField.required" />
          Campo obrigatório
        </label>
        <label class="field-form__checkbox">
          <input type="checkbox" v-model="newField.show_on_card" />
          Mostrar no card do Kanban
        </label>
      </div>

      <div class="field-form__actions">
        <button class="btn-cancel" @click="cancelForm">Cancelar</button>
        <button class="btn-save" @click="saveField" :disabled="!canSave">
          {{ editingField ? 'Atualizar' : 'Criar' }}
        </button>
      </div>
    </div>

    <!-- Fields List -->
    <div v-if="isLoading" class="manager-loading">Carregando...</div>
    
    <div v-else-if="fields.length === 0 && !showForm" class="manager-empty">
      Nenhum campo personalizado criado para este pipeline.
    </div>

    <div v-else class="fields-list">
      <div v-for="field in fields" :key="field.id" class="field-card">
        <div class="field-card__icon">{{ getTypeIcon(field.field_type) }}</div>
        <div class="field-card__info">
          <div class="field-card__name">
            {{ field.name }}
            <span v-if="field.required" class="field-card__required">*</span>
            <span v-if="field.show_on_card" class="field-card__badge">📋 Card</span>
          </div>
          <div class="field-card__meta">
            {{ getTypeName(field.field_type) }}
            <span v-if="field.select_options?.length">
              · {{ field.select_options.length }} opções
            </span>
          </div>
        </div>
        <div class="field-card__actions">
          <button class="btn-icon" @click="editField(field)" title="Editar">✏️</button>
          <button class="btn-icon btn-icon--danger" @click="deleteField(field)" title="Excluir">🗑️</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanCustomFieldsManager',
  props: {
    accountId: {
      type: [Number, String],
      required: true,
    },
    pipelineId: {
      type: [Number, String],
      required: true,
    },
  },
  setup(props) {
    const isLoading = ref(false);
    const fields = ref([]);
    const showForm = ref(false);
    const editingField = ref(null);
    const optionsText = ref('');

    const newField = ref({
      name: '',
      field_type: 'text',
      description: '',
      required: false,
      show_on_card: false,
    });

    const canSave = computed(() => {
      if (!newField.value.name) return false;
      if (['select', 'multiselect'].includes(newField.value.field_type)) {
        return optionsText.value.trim().length > 0;
      }
      return true;
    });

    const loadFields = async () => {
      if (!props.pipelineId) return;
      
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getCustomFields(props.accountId, props.pipelineId);
        fields.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar campos:', error);
      } finally {
        isLoading.value = false;
      }
    };

    const saveField = async () => {
      if (!canSave.value) return;

      const data = { ...newField.value };
      
      if (['select', 'multiselect'].includes(data.field_type)) {
        data.select_options = optionsText.value
          .split('\n')
          .map(o => o.trim())
          .filter(o => o.length > 0);
      }

      try {
        if (editingField.value) {
          await KanbanAPI.updateCustomField(props.accountId, props.pipelineId, editingField.value.id, data);
        } else {
          await KanbanAPI.createCustomField(props.accountId, props.pipelineId, data);
        }
        await loadFields();
        cancelForm();
      } catch (error) {
        console.error('Erro ao salvar campo:', error);
        alert('Erro ao salvar campo');
      }
    };

    const editField = (field) => {
      editingField.value = field;
      newField.value = {
        name: field.name,
        field_type: field.field_type,
        description: field.description || '',
        required: field.required,
        show_on_card: field.show_on_card,
      };
      optionsText.value = (field.select_options || []).join('\n');
      showForm.value = true;
    };

    const deleteField = async (field) => {
      if (!confirm(`Excluir o campo "${field.name}"? Os dados preenchidos serão perdidos.`)) return;

      try {
        await KanbanAPI.deleteCustomField(props.accountId, props.pipelineId, field.id);
        await loadFields();
      } catch (error) {
        console.error('Erro ao excluir campo:', error);
      }
    };

    const cancelForm = () => {
      showForm.value = false;
      editingField.value = null;
      newField.value = {
        name: '',
        field_type: 'text',
        description: '',
        required: false,
        show_on_card: false,
      };
      optionsText.value = '';
    };

    const getTypeIcon = (type) => {
      const icons = {
        text: '📝',
        textarea: '📄',
        number: '🔢',
        currency: '💰',
        select: '📋',
        multiselect: '☑️',
        date: '📅',
        checkbox: '✅',
      };
      return icons[type] || '📝';
    };

    const getTypeName = (type) => {
      const names = {
        text: 'Texto',
        textarea: 'Texto Longo',
        number: 'Número',
        currency: 'Moeda',
        select: 'Dropdown',
        multiselect: 'Múltipla Escolha',
        date: 'Data',
        checkbox: 'Sim/Não',
      };
      return names[type] || type;
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
      showForm,
      editingField,
      newField,
      optionsText,
      canSave,
      saveField,
      editField,
      deleteField,
      cancelForm,
      getTypeIcon,
      getTypeName,
    };
  },
};
</script>

<style scoped>
.custom-fields-manager {
  padding: 16px 0;
}

.manager-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.manager-header__title {
  font-size: 16px;
  font-weight: 600;
  margin: 0;
  color: var(--s-800);
}

.btn-add {
  padding: 8px 16px;
  background-color: var(--w-500);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}

.btn-add:hover {
  background-color: var(--w-600);
}

.manager-loading,
.manager-empty {
  text-align: center;
  padding: 32px;
  color: var(--s-500);
  font-size: 14px;
}

/* Form */
.field-form {
  background-color: var(--s-50);
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.field-form__row {
  display: flex;
  gap: 12px;
}

.field-form__group {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-form__group label {
  font-size: 12px;
  font-weight: 500;
  color: var(--s-700);
}

.field-form__group input,
.field-form__group select,
.field-form__group textarea {
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 13px;
}

.field-form__group textarea {
  resize: vertical;
}

.field-form__checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
}

.field-form__actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 8px;
}

.btn-cancel,
.btn-save {
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}

.btn-cancel {
  background: white;
  border: 1px solid var(--s-300);
  color: var(--s-700);
}

.btn-save {
  background-color: var(--w-500);
  border: none;
  color: white;
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Fields List */
.fields-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.field-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background-color: white;
  border: 1px solid var(--s-200);
  border-radius: 8px;
}

.field-card__icon {
  font-size: 20px;
}

.field-card__info {
  flex: 1;
}

.field-card__name {
  font-size: 14px;
  font-weight: 500;
  color: var(--s-800);
  display: flex;
  align-items: center;
  gap: 6px;
}

.field-card__required {
  color: #ef4444;
}

.field-card__badge {
  font-size: 10px;
  padding: 2px 6px;
  background-color: var(--w-100);
  color: var(--w-700);
  border-radius: 4px;
}

.field-card__meta {
  font-size: 12px;
  color: var(--s-500);
  margin-top: 2px;
}

.field-card__actions {
  display: flex;
  gap: 4px;
}

.btn-icon {
  padding: 6px;
  background: none;
  border: none;
  cursor: pointer;
  border-radius: 4px;
  font-size: 14px;
}

.btn-icon:hover {
  background-color: var(--s-100);
}

.btn-icon--danger:hover {
  background-color: #fee2e2;
}
</style>
