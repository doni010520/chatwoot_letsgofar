<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const store = useStore();

const isOpen = ref(false);
const isSaving = ref(false);
const messageId = ref(null);
const conversationId = ref(null);
const originalContent = ref('');
const editedContent = ref('');
const textareaRef = ref(null);

const MAX_CHARS = 4096;

const charsLeft = computed(() => MAX_CHARS - (editedContent.value?.length || 0));
const hasChanges = computed(
  () =>
    editedContent.value.trim().length > 0 &&
    editedContent.value.trim() !== originalContent.value.trim()
);

const handleOpen = ({ id, conversationId: convId, content }) => {
  messageId.value = id;
  conversationId.value = convId;
  originalContent.value = content || '';
  editedContent.value = content || '';
  isOpen.value = true;
  nextTick(() => textareaRef.value?.focus());
};

const handleClose = () => {
  if (isSaving.value) return;
  isOpen.value = false;
  messageId.value = null;
  conversationId.value = null;
  originalContent.value = '';
  editedContent.value = '';
};

const handleSave = async () => {
  if (!hasChanges.value || isSaving.value) return;
  if (editedContent.value.length > MAX_CHARS) {
    useAlert(`Mensagem excede ${MAX_CHARS} caracteres`);
    return;
  }
  isSaving.value = true;
  try {
    await store.dispatch('updateMessage', {
      conversationId: conversationId.value,
      messageId: messageId.value,
      content: editedContent.value.trim(),
    });
    useAlert('Mensagem editada com sucesso');
    handleClose();
  } catch (error) {
    const apiMsg =
      error?.response?.data?.error ||
      error?.message ||
      'Erro ao editar mensagem';
    useAlert(apiMsg);
  } finally {
    isSaving.value = false;
  }
};

const handleKeydown = e => {
  if (e.key === 'Escape') handleClose();
  if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') handleSave();
};

onMounted(() => {
  emitter.on(BUS_EVENTS.OPEN_EDIT_MESSAGE_MODAL, handleOpen);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.OPEN_EDIT_MESSAGE_MODAL, handleOpen);
});
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/50"
      @click.self="handleClose"
      @keydown="handleKeydown"
    >
      <div
        class="relative w-full max-w-xl rounded-xl bg-n-solid-2 border border-n-weak shadow-2xl"
      >
        <header class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
          <h3 class="text-base font-medium text-n-slate-12">Editar mensagem</h3>
          <button
            class="p-1.5 rounded-lg text-n-slate-11 hover:bg-n-alpha-3"
            @click="handleClose"
          >
            <span class="i-lucide-x text-lg" />
          </button>
        </header>

        <div class="p-6 flex flex-col gap-3">
          <p class="text-xs text-n-slate-11">
            O cliente verá uma marca de "editada" no WhatsApp.
            <strong>Janela de edição: até 15 minutos após o envio.</strong>
          </p>
          <textarea
            ref="textareaRef"
            v-model="editedContent"
            class="w-full min-h-[150px] px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand transition-all resize-none"
            placeholder="Digite o novo conteúdo da mensagem..."
            :maxlength="MAX_CHARS"
          />
          <div class="flex items-center justify-between text-xs">
            <span class="text-n-slate-10">
              Original: {{ originalContent.length }} caracteres
            </span>
            <span :class="charsLeft < 100 ? 'text-n-ruby-11' : 'text-n-slate-10'">
              {{ charsLeft }} restantes
            </span>
          </div>
        </div>

        <footer class="flex items-center justify-end gap-2 px-6 py-3 border-t border-n-weak">
          <button
            class="px-3 py-2 text-sm rounded-lg text-n-slate-12 hover:bg-n-alpha-3"
            :disabled="isSaving"
            @click="handleClose"
          >
            Cancelar
          </button>
          <button
            class="px-4 py-2 text-sm rounded-lg bg-n-brand text-white hover:opacity-90 disabled:opacity-50"
            :disabled="!hasChanges || isSaving"
            @click="handleSave"
          >
            {{ isSaving ? 'Salvando...' : 'Salvar (Ctrl+Enter)' }}
          </button>
        </footer>
      </div>
    </div>
  </Teleport>
</template>
