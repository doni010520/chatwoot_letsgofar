<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  filters: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['change', 'reset', 'close']);

const store = useStore();
const { t } = useI18n();

// Getters
const currentUser = computed(() => store.getters.getCurrentUser);
const isAdmin = computed(() => currentUser.value?.role === 'administrator');
const agents = computed(() => store.getters['agents/getAgents'] || []);
const labels = computed(() => store.getters['labels/getLabels'] || []);
  
// Opções de filtro
const statusOptions = [
  { value: '', label: t('TASKS.FILTERS.ALL') },
  { value: 'active', label: t('TASKS.FILTERS.ACTIVE') },
  { value: 'pending', label: t('TASKS.STATUS.PENDING') },
  { value: 'in_progress', label: t('TASKS.STATUS.IN_PROGRESS') },
  { value: 'completed', label: t('TASKS.STATUS.COMPLETED') },
  { value: 'cancelled', label: t('TASKS.STATUS.CANCELLED') },
];

const priorityOptions = [
  { value: '', label: t('TASKS.FILTERS.ALL') },
  { value: 'urgent', label: t('TASKS.PRIORITY.URGENT') },
  { value: 'high', label: t('TASKS.PRIORITY.HIGH') },
  { value: 'medium', label: t('TASKS.PRIORITY.MEDIUM') },
  { value: 'low', label: t('TASKS.PRIORITY.LOW') },
];

const dueDateOptions = [
  { value: '', label: t('TASKS.FILTERS.ALL') },
  { value: 'overdue', label: t('TASKS.FILTERS.OVERDUE') },
  { value: 'today', label: t('TASKS.FILTERS.TODAY') },
  { value: 'tomorrow', label: t('TASKS.FILTERS.TOMORROW') },
  { value: 'this_week', label: t('TASKS.FILTERS.THIS_WEEK') },
  { value: 'this_month', label: t('TASKS.FILTERS.THIS_MONTH') },
  { value: 'no_date', label: t('TASKS.FILTERS.NO_DATE') },
];

const linkedToOptions = [
  { value: '', label: t('TASKS.FILTERS.ALL') },
  { value: 'contact', label: t('TASKS.FILTERS.WITH_CONTACT') },
  { value: 'conversation', label: t('TASKS.FILTERS.WITH_CONVERSATION') },
  { value: 'pipeline', label: t('TASKS.FILTERS.WITH_PIPELINE') },
  { value: 'none', label: t('TASKS.FILTERS.STANDALONE') },
];

// Handlers
const updateFilter = (key, value) => {
  emit('change', { [key]: value || null });
};

const toggleLabel = labelId => {
  const currentLabels = [...(props.filters.label_ids || [])];
  const index = currentLabels.indexOf(labelId);

  if (index === -1) {
    currentLabels.push(labelId);
  } else {
    currentLabels.splice(index, 1);
  }

  emit('change', { label_ids: currentLabels });
};

const handleReset = () => {
  emit('reset');
};

// Carregar dados ao montar
onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('labels/get');
});
</script>

<template>
  <div class="p-4">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <h3 class="font-semibold text-n-slate-12">
        {{ t('TASKS.FILTERS.TITLE') }}
      </h3>
      <div class="flex items-center gap-2">
        <Button color="slate" size="xs" @click="handleReset">
          {{ t('TASKS.FILTERS.RESET') }}
        </Button>
        <button class="text-n-slate-10 hover:text-n-slate-12" @click="$emit('close')">
          <span class="i-lucide-x size-5" />
        </button>
      </div>
    </div>

    <div class="space-y-4">
      <!-- Status -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FORM.STATUS') }}
        </label>
        <select
          :value="filters.status || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('status', $event.target.value)"
        >
          <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <!-- Prioridade -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FORM.PRIORITY') }}
        </label>
        <select
          :value="filters.priority || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('priority', $event.target.value)"
        >
          <option v-for="opt in priorityOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <!-- Data de Vencimento -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FORM.DUE_DATE') }}
        </label>
        <select
          :value="filters.due_date || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('due_date', $event.target.value)"
        >
          <option v-for="opt in dueDateOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <!-- Responsável -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FORM.ASSIGNED_TO') }}
        </label>
        <select
          :value="filters.assigned_to_id || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('assigned_to_id', $event.target.value)"
        >
          <option value="">{{ t('TASKS.FILTERS.ALL') }}</option>
          <option value="unassigned">{{ t('TASKS.FILTERS.UNASSIGNED') }}</option>
          <option v-for="agent in agents" :key="agent.id" :value="agent.id">
            {{ agent.name }}
          </option>
        </select>
      </div>

      <!-- Criado por -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          Criado por
        </label>
        <select
          :value="filters.created_by_id || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('created_by_id', $event.target.value)"
        >
          <!-- Admin: todos os usuários -->
          <template v-if="isAdmin">
            <option value="">{{ t('TASKS.FILTERS.ALL') }}</option>
            <option v-for="agent in agents" :key="agent.id" :value="agent.id">
              {{ agent.name }}
            </option>
          </template>
          
          <!-- Usuário normal: apenas "Criadas por mim" -->
          <template v-else>
            <option value="">-</option>
            <option :value="currentUser.id">Criadas por mim</option>
          </template>
        </select>
      </div>

      <!-- Vínculo -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FILTERS.LINKED_TO') }}
        </label>
        <select
          :value="filters.linked_to || ''"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          @change="updateFilter('linked_to', $event.target.value)"
        >
          <option v-for="opt in linkedToOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <!-- Labels -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          Labels
        </label>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="label in labels"
            :key="label.id"
            type="button"
            class="px-2 py-1 text-xs rounded-full border transition-colors"
            :class="[
              (filters.label_ids || []).includes(label.id)
                ? 'border-transparent'
                : 'border-n-weak hover:border-n-slate-7',
            ]"
            :style="{
              backgroundColor: (filters.label_ids || []).includes(label.id)
                ? label.color
                : 'transparent',
              color: (filters.label_ids || []).includes(label.id) ? 'white' : label.color,
            }"
            @click="toggleLabel(label.id)"
          >
            {{ label.title }}
          </button>
        </div>
      </div>

      <!-- Ordenação -->
      <div>
        <label class="text-xs font-medium text-n-slate-10 block mb-2">
          {{ t('TASKS.FILTERS.SORT_BY') }}
        </label>
        <div class="grid grid-cols-2 gap-2">
          <select
            :value="filters.sort_by || 'created_at'"
            class="px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            @change="updateFilter('sort_by', $event.target.value)"
          >
            <option value="created_at">{{ t('TASKS.FILTERS.SORT.CREATED') }}</option>
            <option value="due_date">{{ t('TASKS.FILTERS.SORT.DUE_DATE') }}</option>
            <option value="priority">{{ t('TASKS.FILTERS.SORT.PRIORITY') }}</option>
            <option value="title">{{ t('TASKS.FILTERS.SORT.TITLE') }}</option>
          </select>
          <select
            :value="filters.sort_order || 'desc'"
            class="px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
            @change="updateFilter('sort_order', $event.target.value)"
          >
            <option value="desc">{{ t('TASKS.FILTERS.SORT.DESC') }}</option>
            <option value="asc">{{ t('TASKS.FILTERS.SORT.ASC') }}</option>
          </select>
        </div>
      </div>
    </div>
  </div>
</template>
