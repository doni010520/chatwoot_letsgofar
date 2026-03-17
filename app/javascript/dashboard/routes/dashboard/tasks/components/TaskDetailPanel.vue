<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TaskModal from './TaskModal.vue';
import TaskComments from './TaskComments.vue';
import TaskFiles from './TaskFiles.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'updated', 'deleted']);

const store = useStore();
const { t } = useI18n();

// Estado local
const showEditModal = ref(false);
const isDeleting = ref(false);
const activeTab = ref('checklist');
const newItemTitle = ref(''); 
const isAdding = ref(false);

// Computed
const priorityConfig = {
  urgent: { label: t('TASKS.PRIORITY.URGENT'), class: 'bg-ruby-3 text-ruby-11' },
  high: { label: t('TASKS.PRIORITY.HIGH'), class: 'bg-orange-3 text-orange-11' },
  medium: { label: t('TASKS.PRIORITY.MEDIUM'), class: 'bg-amber-3 text-amber-11' },
  low: { label: t('TASKS.PRIORITY.LOW'), class: 'bg-green-3 text-green-11' },
};

const priority = computed(() => priorityConfig[props.task.priority] || priorityConfig.medium);

const formattedDueDate = computed(() => {
  if (!props.task.due_date) return null;
  // Parse direto sem conversão de timezone
  const [year, month, day] = props.task.due_date.split('-');
  const date = new Date(year, month - 1, day); // mês é 0-indexed
  return date.toLocaleDateString('pt-BR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  });
});

const formattedCreatedAt = computed(() => {
  const date = new Date(props.task.created_at);
  return date.toLocaleDateString('pt-BR', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
});

const isActive = computed(() => ['pending', 'in_progress'].includes(props.task.status));

const checklistProgress = computed(() => {
  if (!props.task.items_count || props.task.items_count === 0) return 0;
  return Math.round((props.task.items_completed_count / props.task.items_count) * 100);
});

// Handlers
const handleClose = () => {
  emit('close');
};

const openEditModal = () => {
  showEditModal.value = true;
};

const closeEditModal = () => {
  showEditModal.value = false;
};

const onTaskEdited = () => {
  closeEditModal();
  emit('updated');
};

const handleComplete = async () => {
  try {
    await store.dispatch('agentTasks/completeTask', props.task.id);
    emit('updated');
  } catch (error) {
    console.error('Error completing task:', error);
  }
};

const handleReopen = async () => {
  try {
    await store.dispatch('agentTasks/reopenTask', props.task.id);
    emit('updated');
  } catch (error) {
    console.error('Error reopening task:', error);
  }
};

const handleDelete = async () => {
  if (!confirm(t('TASKS.CONFIRM_DELETE'))) return;

  isDeleting.value = true;
  try {
    await store.dispatch('agentTasks/deleteTask', props.task.id);
    emit('deleted');
  } catch (error) {
    console.error('Error deleting task:', error);
  } finally {
    isDeleting.value = false;
  }
};

const handleStatusChange = async newStatus => {
  try {
    await store.dispatch('agentTasks/updateTask', {
      taskId: props.task.id,
      taskData: { status: newStatus },
    });
    emit('updated');
  } catch (error) {
    console.error('Error updating status:', error);
  }
};

const handleToggleItem = async (item) => {
  try {
    await store.dispatch('agentTasks/toggleItem', {
      taskId: props.task.id,
      itemId: item.id,
    });
    emit('updated');
  } catch (error) {
    console.error('Error toggling item:', error);
  }
};

const handleAddItem = async () => {
  if (!newItemTitle.value.trim()) return;

  isAdding.value = true;
  try {
    await store.dispatch('agentTasks/addItem', {
      taskId: props.task.id,
      title: newItemTitle.value.trim(),
    });
    newItemTitle.value = '';
    emit('updated');
  } catch (error) {
    console.error('Error adding item:', error);
  } finally {
    isAdding.value = false;
  }
};

const getRecurrenceLabel = (type) => {
  const labels = {
    daily: 'Repetição diária',
    weekly: 'Repetição semanal',
    monthly: 'Repetição mensal',
    custom: 'Repetição personalizada'
  };
  return labels[type] || '';
};
  
</script>

<template>
  <aside class="w-96 flex-shrink-0 border-l border-n-weak bg-n-background flex flex-col">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-n-weak">
      <h3 class="font-semibold text-n-slate-12">
        {{ t('DETAILS') }}
      </h3>
      <div class="flex items-center gap-1">
        <!-- Ícone de recorrência -->
        <button
          v-if="task.recurrence_type && task.recurrence_type !== 'none'"
          type="button"
          class="text-blue-500 text-lg"
          :title="getRecurrenceLabel(task.recurrence_type)"
        >
          🔁
        </button>
        
        <Button icon="i-lucide-pencil" color="slate" size="xs" @click="openEditModal" />
        <Button
          icon="i-lucide-trash-2"
          color="slate"
          size="xs"
          :loading="isDeleting"
          @click="handleDelete"
        />
        <Button icon="i-lucide-x" color="slate" size="xs" @click="handleClose" />
      </div>
    </div>

    <!-- Conteúdo -->
    <div class="flex-1 overflow-y-auto">
      <div class="p-4 space-y-4">
        <!-- Título e Status -->
        <div>
          <div class="flex items-start gap-2">
            <span :class="priority.class" class="px-2 py-0.5 text-xs rounded font-medium">
              {{ priority.label }}
            </span>
          </div>
          <h2 class="text-lg font-semibold text-n-slate-12 mt-2">
            {{ task.title }}
          </h2>
        </div>

        <!-- Status selector -->
        <div>
          <label class="text-xs text-n-slate-10 block mb-1">Status</label>
          <select
            :value="task.status"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            @change="handleStatusChange($event.target.value)"
          >
            <option value="pending">{{ t('TASKS.STATUS.PENDING') }}</option>
            <option value="in_progress">{{ t('TASKS.STATUS.IN_PROGRESS') }}</option>
            <option value="completed">{{ t('TASKS.STATUS.COMPLETED') }}</option>
            <option value="cancelled">{{ t('TASKS.STATUS.CANCELLED') }}</option>
          </select>
        </div>

        <!-- Descrição -->
        <div v-if="task.description">
          <label class="text-xs text-n-slate-10 block mb-1">
            {{ t('TASKS.FORM.DESCRIPTION') }}
          </label>
          <p class="text-sm text-n-slate-11 whitespace-pre-wrap">
            {{ task.description }}
          </p>
        </div>

        <!-- Metadados -->
        <div class="space-y-3">
          <!-- Data de vencimento -->
          <div v-if="task.due_date" class="flex items-center gap-2">
            <span class="i-lucide-calendar size-4 text-n-slate-9" />
            <div>
              <span class="text-xs text-n-slate-10 block">{{ t('TASKS.FORM.DUE_DATE') }}</span>
              <span class="text-sm text-n-slate-12">
                {{ formattedDueDate }}
                <span v-if="task.due_time" class="text-n-slate-10">
                  às {{ task.due_time }}
                </span>
              </span>
            </div>
          </div>

          <!-- Responsável -->
          <div class="flex items-center gap-2">
            <span class="i-lucide-user size-4 text-n-slate-9" />
            <div>
              <span class="text-xs text-n-slate-10 block">{{ t('TASKS.FORM.ASSIGNED_TO') }}</span>
              <div v-if="task.assigned_to" class="flex items-center gap-2 mt-1">
                <Avatar
                  :name="task.assigned_to.name"
                  :src="task.assigned_to.avatar_url"
                  size="20px"
                />
                <span class="text-sm text-n-slate-12">{{ task.assigned_to.name }}</span>
              </div>
              <span v-else class="text-sm text-n-slate-10">{{ t('TASKS.UNASSIGNED') }}</span>
            </div>
          </div>

          <!-- Criado por -->
          <div class="flex items-center gap-2">
            <span class="i-lucide-user-plus size-4 text-n-slate-9" />
            <div>
              <span class="text-xs text-n-slate-10 block">{{ t('TASKS.CREATED_BY') }}</span>
              <div v-if="task.created_by" class="flex items-center gap-2 mt-1">
                <Avatar
                  :name="task.created_by.name"
                  :src="task.created_by.avatar_url"
                  size="20px"
                />
                <span class="text-sm text-n-slate-12">
                  {{ task.created_by.name }}
                  <span class="text-n-slate-10">• {{ formattedCreatedAt }}</span>
                </span>
              </div>
            </div>
          </div>

          <!-- Vínculo com contato -->
          <div v-if="task.contact" class="flex items-center gap-2">
            <span class="i-lucide-contact size-4 text-n-slate-9" />
            <div>
              <span class="text-xs text-n-slate-10 block">{{ t('TASKS.LINKED_CONTACT') }}</span>
              <span class="text-sm text-n-slate-12">{{ task.contact.name }}</span>
            </div>
          </div>

          <!-- Vínculo com conversa -->
          <div v-if="task.conversation" class="flex items-center gap-2">
            <span class="i-lucide-message-square size-4 text-n-slate-9" />
            <div>
              <span class="text-xs text-n-slate-10 block">{{ t('TASKS.LINKED_CONVERSATION') }}</span>
              <span class="text-sm text-n-slate-12">#{{ task.conversation.display_id }}</span>
            </div>
          </div>
        </div>

        <!-- Labels -->
        <div v-if="task.labels && task.labels.length > 0">
          <label class="text-xs text-n-slate-10 block mb-2">Labels</label>
          <div class="flex flex-wrap gap-1">
            <span
              v-for="label in task.labels"
              :key="label.id"
              class="px-2 py-0.5 text-xs rounded"
              :style="{ backgroundColor: label.color + '20', color: label.color }"
            >
              {{ label.title }}
            </span>
          </div>
        </div>

        <!-- Tabs: Checklist / Comentários -->
        <div class="border-t border-n-weak pt-4">
          <div class="flex gap-4 mb-4">
            <button
              class="text-sm font-medium pb-2 border-b-2 transition-colors"
              :class="[
                activeTab === 'checklist'
                  ? 'border-n-brand text-n-brand'
                  : 'border-transparent text-n-slate-10 hover:text-n-slate-12',
              ]"
              @click="activeTab = 'checklist'"
            >
              {{ t('Checklist') }}
              <span v-if="task.items_count" class="ml-1 text-xs">
                ({{ task.items_completed_count }}/{{ task.items_count }})
              </span>
            </button>
            <button
              class="text-sm font-medium pb-2 border-b-2 transition-colors"
              :class="[
                activeTab === 'comments'
                  ? 'border-n-brand text-n-brand'
                  : 'border-transparent text-n-slate-10 hover:text-n-slate-12',
              ]"
              @click="activeTab = 'comments'"
            >
              {{ t('Comments') }}
              <span v-if="task.comments_count" class="ml-1 text-xs">
                ({{ task.comments_count }})
              </span>
            </button>

            <!-- Files Tab -->
            <button
              type="button"
              class="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="[
                activeTab === 'files'
                  ? 'bg-n-brand text-white'
                  : 'text-n-slate-11 hover:bg-n-alpha-2',
              ]"
              @click="activeTab = 'files'"
            >
              Anexos
              <span v-if="task.files_count" class="ml-1 text-xs">
                ({{ task.files_count }})
              </span>
            </button>
          </div>

          <!-- Aba Checklist COM CHECKBOXES CLICÁVEIS -->
          <div v-if="activeTab === 'checklist'" class="space-y-3">
            <!-- Barra de progresso -->
            <div v-if="task.items && task.items.length > 0" class="mb-4">
              <div class="flex items-center justify-between text-xs text-n-slate-10 mb-1">
                <span>Progresso</span>
                <span>{{ checklistProgress }}%</span>
              </div>
              <div class="h-1.5 rounded-full bg-n-alpha-3 overflow-hidden">
                <div
                  class="h-full rounded-full bg-green-9 transition-all duration-300"
                  :style="{ width: `${checklistProgress}%` }"
                />
              </div>
            </div>

            <!-- Lista de subtarefas com checkboxes interativos -->
            <div v-if="task.items && task.items.length > 0" class="space-y-2">
              <div
                v-for="item in task.items"
                :key="item.id"
                class="flex items-start gap-3 group py-1"
              >
                <!-- CHECKBOX CLICÁVEL -->
                <button
                  type="button"
                  class="flex-shrink-0 mt-0.5 w-5 h-5 rounded border-2 flex items-center justify-center transition-all cursor-pointer"
                  :style="{
                    borderColor: item.completed ? '#ffffff' : '#4a5568',
                    backgroundColor: item.completed ? '#ffffff' : '#2d3748'
                  }"
                  @click="handleToggleItem(item)"
                >
                  <span v-if="item.completed" class="i-lucide-check w-4 h-4" style="color: #000000; font-weight: bold;" />
                </button>

                <!-- TEXTO DA SUBTAREFA -->
                <span
                  class="flex-1 text-sm select-none"
                  :class="[
                    item.completed ? 'line-through text-n-slate-9' : 'text-n-slate-12',
                  ]"
                >
                  {{ item.title }}
                </span>
              </div>
            </div>
            
            <!-- Campo para adicionar nova subtarefa -->
            <div class="mt-4 flex items-center gap-2">
              <span class="i-lucide-plus w-4 h-4 text-n-slate-9 flex-shrink-0" />
              <input
                v-model="newItemTitle"
                type="text"
                placeholder="Adicionar subtarefa"
                class="flex-1 px-2 py-1.5 text-sm rounded-lg border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand"
                :disabled="isAdding"
                @keyup.enter="handleAddItem"
              />
              <button
                type="button"
                class="px-2 py-1.5 text-sm text-n-brand hover:text-n-brand-dark disabled:opacity-50"
                :disabled="!newItemTitle.trim() || isAdding"
                @click="handleAddItem"
              >
                Adicionar
              </button>
            </div>
            
            <!-- Empty state -->
            <div
              v-if="!task.items || task.items.length === 0"
              class="text-center py-6 text-sm text-n-slate-10"
            >
              Nenhuma subtarefa adicionada
            </div>
          </div>

          <!-- Aba Comentários -->
          <TaskComments v-if="activeTab === 'comments'" :task="task" />
          <TaskFiles v-if="activeTab === 'files'" :task="task" @updated="emit('updated')" />
        </div>
      </div>
    </div>

    <!-- Ação principal -->
    <div class="p-4 border-t border-n-weak">
      <Button
        v-if="isActive"
        class="w-full"
        color="blue"
        icon="i-lucide-check"
        @click="handleComplete"
      >
        {{ t('TASKS.ACTIONS.COMPLETE') }}
      </Button>
      <Button
        v-else-if="task.status === 'completed'"
        class="w-full"
        color="slate"
        icon="i-lucide-rotate-ccw"
        @click="handleReopen"
      >
        {{ t('TASKS.ACTIONS.REOPEN') }}
      </Button>
    </div>

    <!-- Modal de Edição -->
    <TaskModal
      v-if="showEditModal"
      :task="task"
      @close="closeEditModal"
      @updated="onTaskEdited"
    />
  </aside>
</template>
