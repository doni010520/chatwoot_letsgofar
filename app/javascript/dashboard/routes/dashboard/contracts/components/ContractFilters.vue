<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  filters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:filters']);

const searchQuery = ref(props.filters.q || '');
const sortBy = ref(props.filters.sort_by || 'created_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

let searchTimeout = null;

const handleSearch = () => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    emit('update:filters', {
      q: searchQuery.value,
      sort_by: sortBy.value,
      sort_order: sortOrder.value,
    });
  }, 300);
};

const handleSort = () => {
  emit('update:filters', {
    q: searchQuery.value,
    sort_by: sortBy.value,
    sort_order: sortOrder.value,
  });
};

const toggleSortOrder = () => {
  sortOrder.value = sortOrder.value === 'desc' ? 'asc' : 'desc';
  handleSort();
};
</script>

<template>
  <div class="flex items-center gap-3">
    <div class="flex-1">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Buscar por nome, número, email..."
        class="w-full h-8 px-3 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand"
        @input="handleSearch"
      />
    </div>
    <div class="flex items-center gap-2">
      <span class="text-xs text-n-slate-11">Ordenar por:</span>
      <select
        v-model="sortBy"
        class="h-8 px-2 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 focus:outline-n-brand"
        @change="handleSort"
      >
        <option value="created_at">Data de criação</option>
        <option value="title">Título</option>
        <option value="status">Status</option>
        <option value="sent_at">Data de envio</option>
        <option value="signed_at">Data de assinatura</option>
      </select>
      <button
        class="flex items-center justify-center w-8 h-8 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak text-n-slate-11 hover:text-n-slate-12 transition-colors"
        @click="toggleSortOrder"
      >
        <span
          :class="sortOrder === 'desc' ? 'i-lucide-arrow-down' : 'i-lucide-arrow-up'"
          class="text-sm"
        />
      </button>
    </div>
  </div>
</template>
