<script setup>
import { ref, watch, nextTick } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  title: { type: String, default: '' },
  readonly: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue', 'update:title']);

const isEditing = ref(false);
const editMode = ref('visual'); // 'visual' or 'html'
const editableContent = ref(props.modelValue);
const editorRef = ref(null);

watch(() => props.modelValue, val => {
  if (!isEditing.value) editableContent.value = val;
});

const startEditing = () => {
  editableContent.value = props.modelValue;
  isEditing.value = true;
  editMode.value = 'visual';
  nextTick(() => {
    if (editorRef.value) editorRef.value.focus();
  });
};

const saveEditing = () => {
  if (editMode.value === 'visual' && editorRef.value) {
    emit('update:modelValue', editorRef.value.innerHTML);
  } else {
    emit('update:modelValue', editableContent.value);
  }
  isEditing.value = false;
};

const cancelEditing = () => {
  isEditing.value = false;
};

const execCmd = (cmd, value = null) => {
  document.execCommand(cmd, false, value);
  editorRef.value?.focus();
};

const insertLink = () => {
  const url = prompt('URL do link:');
  if (url) execCmd('createLink', url);
};

const inputClass = 'w-full h-10 px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand';
</script>

<template>
  <div class="rounded-xl bg-n-solid-2 border border-n-weak overflow-hidden">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex-1 mr-4">
        <input
          v-if="!readonly && !isEditing"
          type="text"
          :class="inputClass"
          :value="title"
          placeholder="Título do contrato"
          @input="$emit('update:title', $event.target.value)"
        />
        <h3 v-else class="text-base font-medium text-n-slate-12">{{ title }}</h3>
      </div>
      <div v-if="!readonly" class="flex items-center gap-2">
        <template v-if="isEditing">
          <Button
            :label="editMode === 'visual' ? 'Código HTML' : 'Editor Visual'"
            icon="i-lucide-code"
            variant="faded"
            color="slate"
            size="sm"
            @click="editMode = editMode === 'visual' ? 'html' : 'visual'"
          />
          <Button
            label="Cancelar"
            variant="faded"
            color="slate"
            size="sm"
            @click="cancelEditing"
          />
          <Button
            label="Salvar"
            icon="i-lucide-check"
            variant="faded"
            color="blue"
            size="sm"
            @click="saveEditing"
          />
        </template>
        <Button
          v-else
          label="Editar Contrato"
          icon="i-lucide-pencil"
          variant="faded"
          color="slate"
          size="sm"
          @click="startEditing"
        />
      </div>
    </div>

    <!-- Toolbar (visual editing mode) -->
    <div
      v-if="isEditing && editMode === 'visual'"
      class="flex flex-wrap items-center gap-1 px-6 py-2 border-b border-n-weak bg-n-solid-3"
    >
      <button class="toolbar-btn" title="Negrito" @click="execCmd('bold')">
        <span class="i-lucide-bold w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Itálico" @click="execCmd('italic')">
        <span class="i-lucide-italic w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Sublinhado" @click="execCmd('underline')">
        <span class="i-lucide-underline w-4 h-4" />
      </button>
      <div class="w-px h-5 bg-n-weak mx-1" />
      <button class="toolbar-btn" title="Título 1" @click="execCmd('formatBlock', 'h1')">
        <span class="i-lucide-heading-1 w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Título 2" @click="execCmd('formatBlock', 'h2')">
        <span class="i-lucide-heading-2 w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Título 3" @click="execCmd('formatBlock', 'h3')">
        <span class="i-lucide-heading-3 w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Parágrafo" @click="execCmd('formatBlock', 'p')">
        <span class="i-lucide-pilcrow w-4 h-4" />
      </button>
      <div class="w-px h-5 bg-n-weak mx-1" />
      <button class="toolbar-btn" title="Lista" @click="execCmd('insertUnorderedList')">
        <span class="i-lucide-list w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Lista numerada" @click="execCmd('insertOrderedList')">
        <span class="i-lucide-list-ordered w-4 h-4" />
      </button>
      <div class="w-px h-5 bg-n-weak mx-1" />
      <button class="toolbar-btn" title="Alinhar esquerda" @click="execCmd('justifyLeft')">
        <span class="i-lucide-align-left w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Centralizar" @click="execCmd('justifyCenter')">
        <span class="i-lucide-align-center w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Justificar" @click="execCmd('justifyFull')">
        <span class="i-lucide-align-justify w-4 h-4" />
      </button>
      <div class="w-px h-5 bg-n-weak mx-1" />
      <button class="toolbar-btn" title="Link" @click="insertLink">
        <span class="i-lucide-link w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Remover link" @click="execCmd('unlink')">
        <span class="i-lucide-unlink w-4 h-4" />
      </button>
      <div class="w-px h-5 bg-n-weak mx-1" />
      <button class="toolbar-btn" title="Desfazer" @click="execCmd('undo')">
        <span class="i-lucide-undo w-4 h-4" />
      </button>
      <button class="toolbar-btn" title="Refazer" @click="execCmd('redo')">
        <span class="i-lucide-redo w-4 h-4" />
      </button>
    </div>

    <!-- Content -->
    <div class="p-6">
      <!-- Visual Editor -->
      <div
        v-if="isEditing && editMode === 'visual'"
        ref="editorRef"
        contenteditable="true"
        class="contract-preview-content rounded-lg p-8 max-w-none min-h-[500px] outline-none cursor-text"
        v-html="editableContent"
      />

      <!-- HTML Editor -->
      <textarea
        v-else-if="isEditing && editMode === 'html'"
        v-model="editableContent"
        class="w-full min-h-[500px] px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 font-mono focus:outline-n-brand"
      />

      <!-- Read-only preview -->
      <div
        v-else-if="modelValue"
        class="contract-preview-content rounded-lg p-8 max-w-none"
        v-html="modelValue"
      />
      <p v-else class="text-sm text-n-slate-11 text-center py-8">
        Nenhum conteúdo disponível. Preencha os dados nos passos anteriores.
      </p>
    </div>
  </div>
</template>

<style scoped>
.toolbar-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  color: var(--n-slate-11);
  transition: all 0.15s;
}
.toolbar-btn:hover {
  background: var(--n-alpha-3);
  color: var(--n-slate-12);
}

.contract-preview-content {
  background: #ffffff;
  color: #333333;
  font-family: 'Times New Roman', Times, serif;
  font-size: 14px;
  line-height: 1.6;
}

.contract-preview-content :deep(h1),
.contract-preview-content :deep(h2),
.contract-preview-content :deep(h3),
.contract-preview-content :deep(h4) {
  color: #8B0000;
}

.contract-preview-content :deep(table) {
  width: 100%;
  border-collapse: collapse;
}

.contract-preview-content :deep(td),
.contract-preview-content :deep(th) {
  border: 1px solid #cccccc;
  padding: 8px 12px;
  color: #333333;
}

.contract-preview-content :deep(a) {
  color: #8B0000;
}

.contract-preview-content :deep(p) {
  color: #333333;
  margin-bottom: 0.5em;
}
</style>
