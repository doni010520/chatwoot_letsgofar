<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue', 'update:title']);

// Modo de visualização
const viewMode = ref('preview'); // 'preview' ou 'edit'

// Texto de exemplo para placeholder
const placeholderExample = '{{variavel}}';

// Conteúdo local para edição
const localContent = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value),
});

// Título local
const localTitle = computed({
  get: () => props.title,
  set: (value) => emit('update:title', value),
});

// Alternar modo
const toggleMode = () => {
  viewMode.value = viewMode.value === 'preview' ? 'edit' : 'preview';
};
</script>

<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
      <div class="flex items-center justify-between gap-4">
        <div class="flex-1">
          <label class="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
            Título do Contrato
          </label>
          <input
            v-model="localTitle"
            type="text"
            class="w-full px-3 py-2 text-lg font-semibold rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-white focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Título do contrato"
          />
        </div>

        <!-- Toggle de modo -->
        <div class="flex items-center gap-2">
          <div class="flex items-center p-1 rounded-lg bg-slate-100 dark:bg-slate-900">
            <button
              type="button"
              class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md transition-colors"
              :class="[
                viewMode === 'preview'
                  ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'
              ]"
              @click="viewMode = 'preview'"
            >
              <span class="i-lucide-eye text-base" />
              Visualizar
            </button>
            <button
              type="button"
              class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md transition-colors"
              :class="[
                viewMode === 'edit'
                  ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'
              ]"
              @click="viewMode = 'edit'"
            >
              <span class="i-lucide-code text-base" />
              Editar HTML
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="relative">
      <!-- Preview Mode -->
      <div
        v-show="viewMode === 'preview'"
        class="p-8 min-h-[500px] max-h-[70vh] overflow-auto"
      >
        <div
          v-if="localContent"
          class="prose prose-sm max-w-none dark:prose-invert prose-headings:text-rose-800 dark:prose-headings:text-rose-400 prose-table:border-collapse prose-td:border prose-td:border-slate-300 prose-td:p-2"
          v-html="localContent"
        />
        <div
          v-else
          class="flex flex-col items-center justify-center h-64 text-center"
        >
          <span class="i-lucide-file-text text-4xl text-slate-300 dark:text-slate-600 mb-3" />
          <p class="text-slate-500 dark:text-slate-400">
            O conteúdo do contrato aparecerá aqui
          </p>
          <button
            type="button"
            class="mt-3 text-sm text-rose-600 hover:text-rose-700 font-medium"
            @click="viewMode = 'edit'"
          >
            Editar HTML
          </button>
        </div>
      </div>

      <!-- Edit Mode -->
      <div
        v-show="viewMode === 'edit'"
        class="p-4"
      >
        <div class="mb-3 flex items-center justify-between">
          <p class="text-xs text-slate-500 dark:text-slate-400">
            <span class="i-lucide-info mr-1" />
            Você pode editar o HTML do contrato diretamente. Use
            <code class="px-1 py-0.5 rounded bg-slate-100 dark:bg-slate-900 text-rose-600">{{ placeholderExample }}</code>
            para campos dinâmicos.
          </p>
        </div>
        <textarea
          v-model="localContent"
          class="w-full h-[60vh] px-4 py-3 font-mono text-sm rounded-xl border border-slate-300 dark:border-slate-600 bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow resize-none"
          placeholder="Cole ou digite o HTML do contrato aqui..."
        />
      </div>
    </div>

    <!-- Footer com dicas -->
    <div class="px-6 py-3 border-t border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900">
      <div class="flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400">
        <span class="flex items-center gap-1">
          <span class="i-lucide-lightbulb text-amber-500" />
          Dica: Revise o contrato antes de enviar para assinatura
        </span>
        <span class="flex items-center gap-1">
          <span class="i-lucide-printer" />
          <button
            type="button"
            class="hover:text-slate-700 dark:hover:text-slate-200 underline"
            @click="window.print()"
          >
            Imprimir prévia
          </button>
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Estilos para o conteúdo do contrato */
:deep(.prose) {
  font-family: Arial, sans-serif;
}

:deep(.prose h1) {
  font-size: 18pt;
  text-align: center;
  margin-bottom: 20px;
}

:deep(.prose h2) {
  font-size: 14pt;
  margin-top: 25px;
  margin-bottom: 10px;
}

:deep(.prose table) {
  width: 100%;
  margin: 15px 0;
}

:deep(.prose td:first-child) {
  background-color: rgb(245 245 245);
  font-weight: bold;
  width: 200px;
}

:deep(.prose p) {
  text-align: justify;
  margin-bottom: 10px;
}
</style>
