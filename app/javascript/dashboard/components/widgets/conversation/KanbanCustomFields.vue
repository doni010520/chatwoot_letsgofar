<template>
  <div class="kanban-custom-fields">
    <!-- Loading -->
    <div v-if="isLoading" class="custom-fields-loading">
      <span class="loading-spinner"></span>
      Carregando...
    </div>

    <!-- Não está no CRM -->
    <div v-else-if="!hasPipeline" class="custom-fields-empty">
      <span class="empty-icon">📋</span>
      <p>Esta conversa ainda não foi adicionada ao CRM.</p>
      <p class="empty-hint">Adicione a conversa a um pipeline no Kanban para ver os campos.</p>
    </div>

    <!-- Está no CRM mas não tem campos configurados -->
    <div v-else-if="fields.length === 0" class="custom-fields-empty">
      <span class="empty-icon">✓</span>
      <p>Conversa no pipeline: <strong>{{ pipelineName }}</strong></p>
      <p class="empty-hint">Nenhum campo personalizado configurado para este pipeline.</p>
    </div>

    <!-- Fields List -->
    <div v-else class="fields-list">
      <!-- Pipeline Info -->
      <div class="pipeline-info">
        <span class="pipeline-info__label">Pipeline:</span>
        <span class="pipeline-info__name">{{ pipelineName }}</span>
        <span v-if="stageName" class="pipeline-info__stage" :style="{ backgroundColor: stageColor }">
          {{ stageName }}
        </span>
      </div>

      <!-- Fields -->
      <div v-for="field in fields" :key="field.id" class="field-item">
        <label class="field-item__label">
          {{ field.name }}
          <span v-if="field.required" class="field-item__required">*</span>
        </label>

        <!-- Text -->
        <input
          v-if="field.field_type === 'text'"
          type="text"
          class="field-item__input"
          :value="getFieldValue(field.field_key)"
          :placeholder="field.description || 'Digite...'"
          @blur="updateField(field.field_key, $event.target.value)"
          @keyup.enter="updateField(field.field_key, $event.target.value)"
        />

        <!-- Textarea -->
        <textarea
          v-else-if="field.field_type === 'textarea'"
          class="field-item__textarea"
          rows="2"
          :value="getFieldValue(field.field_key)"
          :placeholder="field.description || 'Digite...'"
          @blur="updateField(field.field_key, $event.target.value)"
        />

        <!-- Number -->
        <input
          v-else-if="field.field_type === 'number'"
          type="number"
          class="field-item__input"
          :value="getFieldValue(field.field_key)"
          :placeholder="field.description || '0'"
          @blur="updateField(field.field_key, $event.target.value)"
          @keyup.enter="updateField(field.field_key, $event.target.value)"
        />

        <!-- Currency -->
        <div v-else-if="field.field_type === 'currency'" class="field-item__currency">
          <span class="field-item__currency-prefix">R$</span>
          <input
            type="number"
            step="0.01"
            class="field-item__input field-item__input--currency"
            :value="getFieldValue(field.field_key)"
            placeholder="0,00"
            @blur="updateField(field.field_key, $event.target.value)"
            @keyup.enter="updateField(field.field_key, $event.target.value)"
          />
        </div>

        <!-- Select -->
        <select
          v-else-if="field.field_type === 'select'"
          class="field-item__select"
          :value="getFieldValue(field.field_key)"
          @change="updateField(field.field_key, $event.target.value)"
        >
          <option value="">Selecione...</option>
          <option v-for="opt in field.select_options" :key="opt" :value="opt">
            {{ opt }}
          </option>
        </select>

        <!-- Multiselect -->
        <div v-else-if="field.field_type === 'multiselect'" class="field-item__multiselect">
          <label
            v-for="opt in field.select_options"
            :key="opt"
            class="field-item__checkbox-label"
          >
            <input
              type="checkbox"
              :checked="isMultiselectChecked(field.field_key, opt)"
              @change="toggleMultiselect(field.field_key, opt, $event.target.checked)"
            />
            {{ opt }}
          </label>
        </div>

        <!-- Date -->
        <input
          v-else-if="field.field_type === 'date'"
          type="date"
          class="field-item__input"
          :value="getFieldValue(field.field_key)"
          @change="updateField(field.field_key, $event.target.value)"
        />

        <!-- Checkbox -->
        <label v-else-if="field.field_type === 'checkbox'" class="field-item__checkbox-single">
          <input
            type="checkbox"
            :checked="getFieldValue(field.field_key) === 'true'"
            @change="updateField(field.field_key, $event.target.checked ? 'true' : 'false')"
          />
          Sim
        </label>

        <p v-if="field.description && field.field_type !== 'text' && field.field_type !== 'textarea'" class="field-item__description">
          {{ field.description }}
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanCustomFields',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup(props) {
    const store = useStore();
    const isLoading = ref(false);
    const fields = ref([]);
    const values = ref({});
    const hasPipeline = ref(false);
    const pipelineName = ref('');
    const stageName = ref('');
    const stageColor = ref('#6366F1');

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const loadData = async () => {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getCustomFieldValues(accountId.value, props.conversationId);
        
        // Usar o campo has_pipeline do backend
        hasPipeline.value = response.data.has_pipeline === true;
        fields.value = response.data.fields || [];
        values.value = response.data.values || {};
        
        // Info do pipeline e stage
        if (response.data.pipeline) {
          pipelineName.value = response.data.pipeline.name;
        }
        if (response.data.stage) {
          stageName.value = response.data.stage.name;
          stageColor.value = response.data.stage.color || '#6366F1';
        }
      } catch (error) {
        console.error('Erro ao carregar campos personalizados:', error);
        hasPipeline.value = false;
      } finally {
        isLoading.value = false;
      }
    };

    const getFieldValue = (fieldKey) => {
      return values.value[fieldKey]?.value || '';
    };

    const updateField = async (fieldKey, value) => {
      const currentValue = getFieldValue(fieldKey);
      if (currentValue === value) return;

      try {
        await KanbanAPI.bulkUpdateCustomFieldValues(accountId.value, props.conversationId, {
          [fieldKey]: value
        });
        
        // Atualizar localmente
        if (!values.value[fieldKey]) {
          values.value[fieldKey] = {};
        }
        values.value[fieldKey].value = value;
      } catch (error) {
        console.error('Erro ao atualizar campo:', error);
      }
    };

    const isMultiselectChecked = (fieldKey, option) => {
      const value = getFieldValue(fieldKey);
      if (!value) return false;
      try {
        const arr = JSON.parse(value);
        return Array.isArray(arr) && arr.includes(option);
      } catch {
        return false;
      }
    };

    const toggleMultiselect = async (fieldKey, option, checked) => {
      let currentValue = [];
      const value = getFieldValue(fieldKey);
      
      if (value) {
        try {
          currentValue = JSON.parse(value);
          if (!Array.isArray(currentValue)) currentValue = [];
        } catch {
          currentValue = [];
        }
      }

      if (checked) {
        if (!currentValue.includes(option)) {
          currentValue.push(option);
        }
      } else {
        currentValue = currentValue.filter(v => v !== option);
      }

      await updateField(fieldKey, JSON.stringify(currentValue));
    };

    watch(() => props.conversationId, () => {
      loadData();
    });

    onMounted(() => {
      loadData();
    });

    return {
      isLoading,
      fields,
      values,
      hasPipeline,
      pipelineName,
      stageName,
      stageColor,
      getFieldValue,
      updateField,
      isMultiselectChecked,
      toggleMultiselect,
    };
  },
};
</script>

<style scoped>
.kanban-custom-fields {
  padding: 8px 0;
}

.custom-fields-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 16px;
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

.custom-fields-empty {
  text-align: center;
  padding: 16px;
  color: var(--s-500);
  font-size: 13px;
}

.empty-icon {
  font-size: 24px;
  display: block;
  margin-bottom: 8px;
}

.empty-hint {
  font-size: 11px;
  color: var(--s-400);
  margin-top: 4px;
}

.pipeline-info {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 10px;
  background-color: var(--s-50);
  border-radius: 6px;
  margin-bottom: 12px;
  font-size: 12px;
}

.dark .pipeline-info {
  background-color: var(--s-800);
}

.pipeline-info__label {
  color: var(--s-500);
}

.pipeline-info__name {
  font-weight: 500;
  color: var(--s-700);
}

.dark .pipeline-info__name {
  color: var(--s-200);
}

.pipeline-info__stage {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  color: white;
  font-weight: 500;
}

.fields-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-item__label {
  font-size: 12px;
  font-weight: 500;
  color: var(--s-700);
}

.dark .field-item__label {
  color: var(--s-300);
}

.field-item__required {
  color: #ef4444;
}

.field-item__input,
.field-item__textarea,
.field-item__select {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 13px;
  background-color: var(--color-background);
  color: var(--color-body);
  transition: border-color 0.2s;
}

.dark .field-item__input,
.dark .field-item__textarea,
.dark .field-item__select {
  background-color: var(--s-800);
  border-color: var(--s-600);
  color: var(--s-100);
}

.field-item__input:focus,
.field-item__textarea:focus,
.field-item__select:focus {
  outline: none;
  border-color: var(--w-500);
}

.field-item__input::placeholder,
.field-item__textarea::placeholder {
  color: var(--s-400);
}

.field-item__textarea {
  resize: vertical;
  min-height: 60px;
}

.field-item__currency {
  display: flex;
  align-items: center;
  gap: 0;
}

.field-item__currency-prefix {
  padding: 8px 10px;
  background-color: var(--s-100);
  border: 1px solid var(--s-200);
  border-right: none;
  border-radius: 6px 0 0 6px;
  font-size: 13px;
  color: var(--s-600);
}

.dark .field-item__currency-prefix {
  background-color: var(--s-700);
  border-color: var(--s-600);
  color: var(--s-300);
}

.field-item__input--currency {
  border-radius: 0 6px 6px 0;
}

.field-item__multiselect {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 8px;
  background-color: var(--s-50);
  border-radius: 6px;
}

.dark .field-item__multiselect {
  background-color: var(--s-800);
}

.field-item__checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
  color: var(--s-700);
}

.dark .field-item__checkbox-label {
  color: var(--s-300);
}

.field-item__checkbox-single {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
  color: var(--s-700);
}

.dark .field-item__checkbox-single {
  color: var(--s-300);
}

.field-item__description {
  font-size: 11px;
  color: var(--s-500);
  margin: 0;
}
</style>
