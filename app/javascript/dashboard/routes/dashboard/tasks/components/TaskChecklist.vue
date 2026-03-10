<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
  canModify: {
    type: Boolean,
    default: false,
  },
});
  
const emit = defineEmits(['updated']);

const store = useStore();
const { t } = useI18n();

// Estado local
const newItemTitle = ref('');
const isAdding = ref(false);

// Computed
const items = computed(() => props.task.items || []);

const progress = computed(() => {
  if (items.value.length === 0) return 0;
  const completed = items.value.filter(i => i.completed).length;
  return Math.round((completed / items.value.length) * 100);
});

// Handlers
const handleToggle = async item => {
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

const handleAdd = async () => {
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

const handleDelete = async item => {
  try {
    await store.dispatch('agentTasks/deleteItem', {
      taskId: props.task.id,
      itemId: item.id,
    });
    emit('updated');
  } catch (error) {
    console.error('Error deleting item:', error);
  }
};
</script>

<template>
  <div>
    <!-- Barra de progresso -->
    <div v-if="items.length > 0" class="mb-4">
      <div class="flex items-center justify-between text-xs text-n-slate-10 mb-1">
        <span>{{ t('TASKS.CHECKLIST_PROGRESS') }}</span>
        <span>{{ progress }}%</span>
      </div>
      <div class="h-1.5 rounded-full bg-n-alpha-3 overflow-hidden">
        <div
          class="h-full rounded-full bg-green-9 transition-all duration-300"
          :style="{ width: `${progress}%` }"
        />
      </div>
    </div>

    <!-- Lista de itens -->
    <div class="space-y-2">
      <div
        v-for="item in items"
        :key="item.id"
        class="flex items-start gap-2 group"
      >
        <button
          :disabled="!canModify"
          class="flex-shrink-0 mt-0.5 size-5 rounded border-2 flex items-center justify-center transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          :class="[
            item.completed
              ? 'border-green-9 bg-green-9 text-white'
              : 'border-n-slate-7 hover:border-n-brand',
          ]"
          @click="handleToggle(item)"
        >
          <span v-if="item.completed" class="i-lucide-check size-3" />
        </button>>

        <span
          class="flex-1 text-sm"
          :class="[
            item.completed ? 'line-through text-n-slate-9' : 'text-n-slate-12',
          ]"
        >
          {{ item.title }}
        </span>

        <button
          :disabled="!canModify"
          class="flex-shrink-0 p-1 opacity-0 group-hover:opacity-100 text-n-slate-9 hover:text-ruby-9 transition-all disabled:cursor-not-allowed"
          @click="handleDelete(item)"
        >
          <span class="i-lucide-x size-4" />
        </button>

        <!-- Adicionar novo item -->
        <div class="mt-3 flex items-center gap-2">
          <span class="i-lucide-plus size-4 text-n-slate-9 flex-shrink-0" />
          <input
            v-model="newItemTitle"
            type="text"
            :placeholder="t('TASKS.FORM.ADD_SUBTASK')"
            class="flex-1 px-2 py-1.5 text-sm rounded-lg border border-n-weak bg-n-background focus:outline-none focus:ring-2 focus:ring-n-brand disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="isAdding || !canModify"
            @keyup.enter="handleAdd"
          />
          <button
            class="px-2 py-1.5 text-sm text-n-brand hover:text-n-brand-dark disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!newItemTitle.trim() || isAdding || !canModify"
            @click="handleAdd"
          >
            {{ t('TASKS.FORM.ADD') }}
          </button>
        </div>

    <!-- Empty state -->
    <div
      v-if="items.length === 0"
      class="text-center py-4 text-sm text-n-slate-10"
    >
      {{ t('TASKS.CHECKLIST_EMPTY') }}
    </div>
  </div>
</template>
