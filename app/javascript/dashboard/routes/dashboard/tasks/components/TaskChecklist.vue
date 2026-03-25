<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});
  
const emit = defineEmits(['updated']);

const store = useStore();
const { t } = useI18n();

// Estado local
const newItemTitle = ref('');
const isAdding = ref(false);
const isDragging = ref(false);
const isReordering = ref(false); // Flag para bloquear watch durante reorder

// Estado para edição inline
const editingItemId = ref(null);
const editingItemTitle = ref('');

const localItems = ref([]);

// Sincroniza items quando mudam - MAS NÃO durante reorder
const syncItems = () => {
  localItems.value = [...(props.task.items || [])];
};

// Inicializa
syncItems();

// Watch para sincronizar quando task muda - respeitando flag isReordering
watch(
  () => props.task.items,
  (newItems, oldItems) => {
    // Só sincroniza se NÃO estiver no meio de um reorder
    if (!isReordering.value) {
      syncItems();
    }
  },
  { deep: true }
);

const progress = computed(() => {
  if (localItems.value.length === 0) return 0;
  const completed = localItems.value.filter(i => i.completed).length;
  return Math.round((completed / localItems.value.length) * 100);
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

const handleDragStart = () => {
  isDragging.value = true;
  isReordering.value = true; // Bloqueia watch ANTES de começar
};

const handleDragEnd = async () => {
  isDragging.value = false;
  
  try {
    const itemIds = localItems.value.map(item => item.id);
    
    // Chama a API para salvar a nova ordem
    await store.dispatch('agentTasks/reorderItems', {
      taskId: props.task.id,
      itemIds,
    });
    
    // A store já foi atualizada via mutation SET_TASK_ITEMS_ORDER
    // NÃO chamamos emit('updated') aqui para evitar recarregar a lista
    // e potencialmente sobrescrever a ordem
    
    // Aguarda um pouco antes de liberar o watch
    setTimeout(() => {
      isReordering.value = false;
    }, 500);
    
  } catch (error) {
    console.error('Error reordering items:', error);
    isReordering.value = false;
    // Reverte para ordem original em caso de erro
    syncItems();
  }
};

// Handlers de edição inline
const startEditItem = (item) => {
  editingItemId.value = item.id;
  editingItemTitle.value = item.title;
};

const saveEditItem = async (item) => {
  if (!editingItemTitle.value.trim()) {
    editingItemId.value = null;
    return;
  }

  try {
    await store.dispatch('agentTasks/updateItem', {
      taskId: props.task.id,
      itemId: item.id,
      data: { title: editingItemTitle.value.trim() }
    });
    editingItemId.value = null;
    emit('updated');
  } catch (error) {
    console.error('Error updating item:', error);
  }
};

const cancelEditItem = () => {
  editingItemId.value = null;
  editingItemTitle.value = '';
};
</script>

<template>
  <div>
    <!-- Barra de progresso -->
    <div v-if="localItems.length > 0" class="mb-4">
      <div class="flex items-center justify-between text-xs text-n-slate-10 mb-1">
        <span>Progresso</span>
        <span>{{ progress }}%</span>
      </div>
      <div class="h-1.5 rounded-full bg-n-alpha-3 overflow-hidden">
        <div
          class="h-full rounded-full bg-green-9 transition-all duration-300"
          :style="{ width: `${progress}%` }"
        />
      </div>
    </div>

    <!-- Lista de itens COM DRAG AND DROP -->
    <Draggable
      v-model="localItems"
      item-key="id"
      handle=".drag-handle"
      ghost-class="opacity-50"
      animation="200"
      class="space-y-2"
      @start="handleDragStart"
      @end="handleDragEnd"
    >
      <template #item="{ element: item }">
        <div
          class="flex items-start gap-2 group py-1.5 px-2 rounded-lg hover:bg-n-alpha-2 transition-colors"
        >
          <!-- HANDLE DE ARRASTAR -->
          <button
            type="button"
            class="drag-handle flex-shrink-0 mt-0.5 p-0.5 cursor-grab active:cursor-grabbing opacity-0 group-hover:opacity-100 transition-opacity text-n-slate-9 hover:text-n-slate-11"
          >
            <span class="i-lucide-grip-vertical w-4 h-4" />
          </button>

          <!-- CHECKBOX MENOR (w-4 h-4) COM BORDA VISÍVEL -->"button"
          <button
            type=
            class="flex-shrink-0 mt-0.5 size-4 box-border rounded-sm flex items-center justify-center transition-colors cursor-pointer"
            :style="{
              backgroundColor: item.completed ? 'rgb(var(--green-9))' : 'transparent',
              border: item.completed 
                ? '2px solid rgb(var(--green-9))' 
                : '2px solid rgb(var(--slate-11))'
            }"
            @click="handleToggle(item)"
          >
            <span v-if="item.completed" class="i-lucide-check w-2.5 h-2.5 text-white" />
          </button>

          <!-- TEXTO DA SUBTAREFA (editável ao clicar) -->
          <div v-if="editingItemId === item.id" class="flex-1 flex items-center gap-2">
            <input
              v-model="editingItemTitle"
              type="text"
              class="flex-1 px-2 py-0.5 text-sm rounded border border-n-brand bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
              @keyup.enter="saveEditItem(item)"
              @keyup.esc="cancelEditItem"
              @blur="saveEditItem(item)"
              autofocus
            />
          </div>
          <span
            v-else
            class="flex-1 text-sm cursor-pointer hover:text-n-brand"
            :class="[
              item.completed ? 'line-through text-n-slate-9' : 'text-n-slate-12',
            ]"
            @click="startEditItem(item)"
          >
            {{ item.title }}
          </span>

          <!-- BOTÃO DELETAR -->
          <button
            type="button"
            class="flex-shrink-0 p-1 opacity-0 group-hover:opacity-100 text-n-slate-9 hover:text-ruby-9 hover:bg-ruby-500/10 rounded transition-all"
            @click="handleDelete(item)"
          >
            <span class="i-lucide-x w-4 h-4" />
          </button>
        </div>
      </template>
    </Draggable>

    <!-- Adicionar novo item -->
    <div class="mt-3 flex items-center gap-2">
      <span class="i-lucide-plus w-4 h-4 text-n-slate-9 flex-shrink-0" />
      <input
        v-model="newItemTitle"
        type="text"
        placeholder="Adicionar subtarefa"
        class="flex-shrink-0 mt-0.5 w-4 h-4 flex items-center justify-center transition-colors cursor-pointer"
        :disabled="isAdding"
        @keyup.enter="handleAdd"
      />
      <button
        type="button"
        class="px-2 py-1.5 text-sm text-n-brand hover:text-n-brand-dark disabled:opacity-50"
        :disabled="!newItemTitle.trim() || isAdding"
        @click="handleAdd"
      >
        Adicionar
      </button>
    </div>

    <!-- Empty state -->
    <div
      v-if="localItems.length === 0"
      class="text-center py-6 text-sm text-n-slate-10"
    >
      Nenhuma subtarefa. Adicione uma acima.
    </div>
  </div>
</template>
