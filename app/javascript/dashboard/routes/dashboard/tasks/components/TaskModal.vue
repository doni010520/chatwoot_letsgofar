<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';

const props = defineProps({
  task: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'created', 'updated']);

const store = useStore();
const { t } = useI18n();

// Estado do formulário
const formData = ref({
  title: '',
  description: '',
  priority: 'medium',
  status: 'pending',
  due_date: '',
  due_time: '',
  assigned_to_id: null,
  contact_id: null,
  conversation_id: null,
  kanban_pipeline_id: null,
  label_ids: [],
});

// Subtarefas
const newItemTitle = ref('');
const items = ref([]);

// UI Flags
const isSubmitting = ref(false);
const errors = ref({});

// Getters
const agents = computed(() => store.getters['agents/getAgents'] || []);
const labels = computed(() => store.getters['labels/getLabels'] || []);

// É edição?
const isEditing = computed(() => !!props.task);
const modalTitle = computed(() =>
  isEditing.value ? t('TASKS.EDIT_TASK') : t('TASKS.NEW_TASK')
);

// Opções de prioridade
const priorityOptions = [
  { value: 'low', label: t('TASKS.PRIORITY.LOW') },
  { value: 'medium', label: t('TASKS.PRIORITY.MEDIUM') },
  { value: 'high', label: t('TASKS.PRIORITY.HIGH') },
  { value: 'urgent', label: t('TASKS.PRIORITY.URGENT') },
];

// Opções de status
const statusOptions = [
  { value: 'pending', label: t('TASKS.STATUS.PENDING') },
  { value: 'in_progress', label: t('TASKS.STATUS.IN_PROGRESS') },
  { value: 'completed', label: t('TASKS.STATUS.COMPLETED') },
  { value: 'cancelled', label: t('TASKS.STATUS.CANCELLED') },
];

// Handlers
const addItem = () => {
  if (!newItemTitle.value.trim()) return;

  items.value.push({
    id: `new_${Date.now()}`,
    title: newItemTitle.value.trim(),
    completed: false,
    _new: true,
  });
  newItemTitle.value = '';
};

const removeItem = index => {
  const item = items.value[index];
  if (item._new) {
    items.value.splice(index, 1);
  } else {
    items.value[index]._destroy = true;
  }
};

const toggleLabel = labelId => {
  const index = formData.value.label_ids.indexOf(labelId);
  if (index === -1) {
    formData.value.label_ids.push(labelId);
  } else {
    formData.value.label_ids.splice(index, 1);
  }
};

const validateForm = () => {
  errors.value = {};

  if (!formData.value.title.trim()) {
    errors.value.title = t('TASKS.VALIDATION.TITLE_REQUIRED');
  }

  return Object.keys(errors.value).length === 0;
};

const handleSubmit = async () => {
  if (!validateForm()) return;

  isSubmitting.value = true;

  try {
    const taskData = {
      ...formData.value,
      items_attributes: items.value
        .filter(i => !i._destroy || !i._new)
        .map(i => ({
          id: i._new ? undefined : i.id,
          title: i.title,
          completed: i.completed,
          _destroy: i._destroy,
        })),
    };

    if (isEditing.value) {
      await store.dispatch('agentTasks/updateTask', {
        taskId: props.task.id,
        taskData,
      });
      emit('updated');
    } else {
      const newTask = await store.dispatch('agentTasks/createTask', taskData);
      emit('created', newTask);
    }
  } catch (error) {
    console.error('Error saving task:', error);
  } finally {
    isSubmitting.value = false;
  }
};

const handleClose = () => {
  emit('close');
};

// Preencher dados se for edição
onMounted(() => {
  if (props.task) {
    formData.value = {
      title: props.task.title || '',
      description: props.task.description || '',
      priority: props.task.priority || 'medium',
      status: props.task.status || 'pending',
      due_date: props.task.due_date || '',
      due_time: props.task.due_time || '',
      assigned_to_id: props.task.assigned_to?.id || null,
      contact_id: props.task.contact?.id || null,
      conversation_id: props.task.conversation?.id || null,
      kanban_pipeline_id: props.task.kanban_pipeline?.id || null,
      label_ids: props.task.labels?.map(l => l.id) || [],
    };
    items.value = props.task.items || [];
  }

  store.dispatch('agents/get');
  store.dispatch('labels/get');
});
</script>

<template>
  <Modal :show="true" :on-close="handleClose">
    <div class="p-6">
      <h2 class="text-lg font-medium text-n-slate-12 mb-4">{{ modalTitle }}</h2>
      
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <!-- Título -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('TASKS.FORM.TITLE') }} *
          </label>
          <input
            v-model="formData.title"
            type="text"
            :placeholder="t('TASKS.FORM.TITLE_PLACEHOLDER')"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            :class="{ 'border-ruby-9': errors.title }"
          />
          <p v-if="errors.title" class="mt-1 text-xs text-ruby-11">{{ errors.title }}</p>
        </div>

        <!-- Descrição -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('TASKS.FORM.DESCRIPTION') }}
          </label>
          <textarea
            v-model="formData.description"
            :placeholder="t('TASKS.FORM.DESCRIPTION_PLACEHOLDER')"
            rows="3"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
          />
        </div>

        <!-- Linha: Responsável + Prioridade -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              {{ t('TASKS.FORM.ASSIGNED_TO') }}
            </label>
            <select
              v-model="formData.assigned_to_id"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            >
              <option :value="null">{{ t('TASKS.FORM.UNASSIGNED') }}</option>
              <option v-for="agent in agents" :key="agent.id" :value="agent.id">
                {{ agent.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              {{ t('TASKS.FORM.PRIORITY') }}
            </label>
            <select
              v-model="formData.priority"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            >
              <option v-for="opt in priorityOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </div>
        </div>

        <!-- Linha: Data + Hora -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              {{ t('TASKS.FORM.DUE_DATE') }}
            </label>
            <input
              v-model="formData.due_date"
              type="date"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              {{ t('TASKS.FORM.DUE_TIME') }}
            </label>
            <input
              v-model="formData.due_time"
              type="time"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            />
          </div>
        </div>

        <!-- Status (apenas em edição) -->
        <div v-if="isEditing">
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('TASKS.FORM.STATUS') }}
          </label>
          <select
            v-model="formData.status"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Labels -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('TASKS.FORM.LABELS') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="label in labels"
              :key="label.id"
              type="button"
              class="px-2 py-1 text-xs rounded-full border transition-colors"
              :class="[
                formData.label_ids.includes(label.id)
                  ? 'border-transparent'
                  : 'border-n-weak hover:border-n-slate-7',
              ]"
              :style="{
                backgroundColor: formData.label_ids.includes(label.id) ? label.color : 'transparent',
                color: formData.label_ids.includes(label.id) ? 'white' : label.color,
              }"
              @click="toggleLabel(label.id)"
            >
              {{ label.title }}
            </button>
          </div>
        </div>

        <!-- Subtarefas -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('TASKS.FORM.SUBTASKS') }}
          </label>

          <div class="space-y-2">
            <div
              v-for="(item, index) in items.filter(i => !i._destroy)"
              :key="item.id"
              class="flex items-center gap-2"
            >
              <input
                type="checkbox"
                :checked="item.completed"
                class="size-4 rounded border-n-slate-7"
                @change="item.completed = $event.target.checked"
              />
              <input
                v-model="item.title"
                type="text"
                class="flex-1 px-2 py-1 text-sm rounded border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand"
              />
              <button
                type="button"
                class="p-1 text-n-slate-9 hover:text-ruby-9"
                @click="removeItem(index)"
              >
                <span class="i-lucide-x size-4" />
              </button>
            </div>

            <!-- Adicionar nova subtarefa -->
            <div class="flex items-center gap-2">
              <span class="i-lucide-plus size-4 text-n-slate-9" />
              <input
                v-model="newItemTitle"
                type="text"
                :placeholder="t('TASKS.FORM.ADD_SUBTASK')"
                class="flex-1 px-2 py-1 text-sm rounded border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand"
                @keyup.enter="addItem"
              />
              <Button
                type="button"
                color="slate"
                size="xs"
                :disabled="!newItemTitle.trim()"
                @click="addItem"
              >
                {{ t('TASKS.FORM.ADD') }}
              </Button>
            </div>
          </div>
        </div>

        <!-- Ações -->
        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <Button type="button" color="slate" @click="handleClose">
            {{ t('COMMON.CANCEL') }}
          </Button>
          <Button type="submit" color="blue" :loading="isSubmitting">
            {{ isEditing ? t('COMMON.SAVE') : t('TASKS.FORM.CREATE') }}
          </Button>
        </div>
      </form>
    </div>
  </Modal>
</template>
