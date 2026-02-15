<template>
  <div class="kanban-custom-fields">
    <!-- Loading -->
    <div v-if="isLoading" class="custom-fields-loading">Carregando...</div>

    <!-- No Pipeline -->
    <div v-else-if="!hasPipeline" class="custom-fields-empty">
      Selecione um estágio no Kanban para ver os campos
    </div>

    <!-- No Fields -->
    <div v-else-if="fields.length === 0" class="custom-fields-empty">
      Nenhum campo personalizado configurado
    </div>

    <!-- Fields List -->
    <div v-else class="fields-list">
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
          @blur="updateField(field.field_key, $event.target.value)"
          @keyup.enter="updateField(field.field_key, $event.target.value)"
        />

        <!-- Textarea -->
        <textarea
          v-else-if="field.field_type === 'textarea'"
          class="field-item__textarea"
          rows="2"
          :value="getFieldValue(field.field_key)"
          @blur="updateField(field.field_key, $event.target.value)"
        />

        <!-- Number -->
        <input
          v-else-if="field.field_type === 'number'"
          type="number"
          class="field-item__input"
          :value="getFieldValue(field.field_key)"
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

        <p v-if="field.description" class="field-item__description">
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

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const loadData = async () => {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getCustomFieldValues(accountId.value, props.conversationId);
        fields.value = response.data.fields || [];
        values.value = response.data.values || {};
        hasPipeline.value = fields.value.length > 0 || Object.keys(response.data).length > 0;
        
        // Se não tem fields mas retornou dados, significa que tem pipeline mas sem campos
        if (response.data.fields !== undefined) {
          hasPipeline.value = true;
        }
      } catch (error) {
        console.error('Erro ao carregar campos personalizados:', error);
        // Se deu 404 ou similar, não tem pipeline
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

.custom-fields-loading,
.custom-fields-empty {
  text-align: center;
  padding: 16px;
  color: var(--s-500);
  font-size: 13px;
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
  background-color: white;
  transition: border-color 0.2s;
}

.field-item__input:focus,
.field-item__textarea:focus,
.field-item__select:focus {
  outline: none;
  border-color: var(--w-500);
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

.field-item__checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
}

.field-item__checkbox-single {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  cursor: pointer;
}

.field-item__description {
  font-size: 11px;
  color: var(--s-500);
  margin: 0;
}
</style>
