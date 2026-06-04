<script setup>
import { formatContractDate } from '../dateHelpers';

defineProps({
  contract: {
    type: Object,
    required: true,
  },
});

defineEmits(['click']);

const statusConfig = {
  draft: { label: 'Rascunho', class: 'bg-n-slate-3 text-n-slate-11' },
  pending: { label: 'Pendente', class: 'bg-n-amber-3 text-n-amber-11' },
  partially_signed: { label: 'Parcial', class: 'bg-n-blue-3 text-n-blue-11' },
  signed: { label: 'Assinado', class: 'bg-n-teal-3 text-n-teal-11' },
  refused: { label: 'Recusado', class: 'bg-n-ruby-3 text-n-ruby-11' },
  expired: { label: 'Expirado', class: 'bg-n-slate-3 text-n-slate-11' },
  cancelled: { label: 'Cancelado', class: 'bg-n-slate-3 text-n-slate-11' },
};

const getStatus = status =>
  statusConfig[status] || { label: status, class: 'bg-n-slate-3 text-n-slate-11' };

// Usa formatContractDate para evitar deslocamento de 1 dia (bug timezone)
// quando a data vem como "YYYY-MM-DD" do input.
const formatDate = dateStr => formatContractDate(dateStr, '-');
</script>

<template>
  <div
    class="flex items-center justify-between p-4 rounded-lg bg-n-solid-2 border border-n-weak cursor-pointer hover:bg-n-alpha-2 transition-colors"
    @click="$emit('click')"
  >
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2 mb-1">
        <p class="text-sm font-medium text-n-slate-12 truncate">
          {{ contract.title }}
        </p>
        <span
          class="px-2 py-0.5 text-xs font-medium rounded-full shrink-0"
          :class="getStatus(contract.status).class"
        >
          {{ getStatus(contract.status).label }}
        </span>
      </div>
      <div class="flex items-center gap-4 text-xs text-n-slate-11">
        <span>{{ contract.contract_number }}</span>
        <span v-if="contract.contractor_name">{{ contract.contractor_name }}</span>
        <span v-if="contract.plan_name">{{ contract.plan_name }}</span>
        <span>{{ formatDate(contract.created_at) }}</span>
      </div>
    </div>

    <div class="flex items-center gap-3 ml-4 shrink-0">
      <div v-if="contract.signature_progress" class="text-right">
        <p class="text-xs text-n-slate-11">
          {{ contract.signature_progress.signed }}/{{ contract.signature_progress.total }}
        </p>
        <div class="w-16 h-1 mt-1 rounded-full bg-n-alpha-3">
          <div
            class="h-full rounded-full bg-n-teal-9 transition-all"
            :style="{ width: `${contract.signature_progress.percentage}%` }"
          />
        </div>
      </div>
      <span class="i-lucide-chevron-right text-n-slate-10" />
    </div>
  </div>
</template>
