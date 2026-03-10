<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  filters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:filters']);

// Busca local com debounce
const searchQuery = ref(props.filters.q || '');
let debounceTimer = null;

// Ordenação
const sortOptions = [
  { value: 'created_at', label: 'Data de criação' },
  { value: 'title', label: 'Título' },
  { value: 'sent_at', label: 'Data de envio' },
  { value: 'signed_at', label: 'Data de assinatura' },
];

const currentSort = ref(props.filters.sort_by || 'created_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

// Aplicar busca com debounce
watch(searchQuery, (newVal) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    emit('update:filters', {
      ...props.filters,
      q: newVal,
    });
  }, 300);
});

// Aplicar ordenação
const applySort = () => {
  emit('update:filters', {
    ...props.filters,
    sort_by: currentSort.value,
    sort_order: sortOrder.value,
  });
};

// Toggle ordem
const toggleSortOrder = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  applySort();
};

// Sincronizar com props
watch(
  () => props.filters,
  (newVal) => {
    if (newVal.q !== searchQuery.value) {
      searchQuery.value = newVal.q || '';
    }
    if (newVal.sort_by !== currentSort.value) {
      currentSort.value = newVal.sort_by || 'created_at';
    }
    if (newVal.sort_order !== sortOrder.value) {
      sortOrder.value = newVal.sort_order || 'desc';
    }
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-wrap items-center gap-4">
    <!-- Busca -->
    <div class="relative flex-1 min-w-[200px] max-w-md">
      <span class="absolute left-3 top-1/2 -translate-y-1/2 i-lucide-search text-slate-400 dark:text-slate-500" />
      <input
        v-model="searchQuery"
        type="text"
        class="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
        placeholder="Buscar por nome, número, email..."
      />
      <button
        v-if="searchQuery"
        type="button"
        class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
        @click="searchQuery = ''"
      >
        <span class="i-lucide-x" />
      </button>
    </div>

    <!-- Ordenação -->
    <div class="flex items-center gap-2">
      <span class="text-sm text-slate-500 dark:text-slate-400 hidden sm:inline">
        Ordenar por:
      </span>
      <select
        v-model="currentSort"
        class="px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-white text-sm focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
        @change="applySort"
      >
        <option v-for="option in sortOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <!-- Toggle asc/desc -->
      <button
        type="button"
        class="p-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
        :title="sortOrder === 'asc' ? 'Ordem crescente' : 'Ordem decrescente'"
        @click="toggleSortOrder"
      >
        <span
          :class="sortOrder === 'asc' ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
          class="text-lg"
        />
      </button>
    </div>
  </div>
</template>
