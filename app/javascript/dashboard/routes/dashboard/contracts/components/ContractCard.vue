<script setup>
import { computed } from 'vue';

const props = defineProps({
  contract: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['click']);

// Status badge config
const statusConfig = computed(() => {
  const configs = {
    draft: { 
      label: 'Rascunho', 
      class: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400',
      icon: 'i-lucide-file-edit'
    },
    pending: { 
      label: 'Aguardando', 
      class: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
      icon: 'i-lucide-clock'
    },
    partially_signed: { 
      label: 'Parcial', 
      class: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      icon: 'i-lucide-edit-3'
    },
    signed: { 
      label: 'Assinado', 
      class: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      icon: 'i-lucide-check-circle'
    },
    refused: { 
      label: 'Recusado', 
      class: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
      icon: 'i-lucide-x-circle'
    },
    expired: { 
      label: 'Expirado', 
      class: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
      icon: 'i-lucide-clock'
    },
    cancelled: { 
      label: 'Cancelado', 
      class: 'bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-500',
      icon: 'i-lucide-ban'
    },
  };
  return configs[props.contract.status] || configs.draft;
});

// Progresso das assinaturas
const signatureProgress = computed(() => {
  const progress = props.contract.signature_progress || { signed: 0, total: 0, percentage: 0 };
  return progress;
});

// Formatar data
const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

// Formatar moeda
const formatCurrency = (value) => {
  if (!value) return '-';
  return parseFloat(value).toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  });
};
</script>

<template>
  <div
    class="group bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5 hover:shadow-lg hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 hover:border-rose-200 dark:hover:border-rose-800 transition-all duration-300 cursor-pointer"
    @click="emit('click', contract)"
  >
    <div class="flex items-start gap-4">
      <!-- Ícone do contrato -->
      <div
        class="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center transition-transform group-hover:scale-110 duration-300"
        :class="[
          contract.status === 'signed' 
            ? 'bg-gradient-to-br from-green-500 to-green-600' 
            : contract.status === 'refused'
              ? 'bg-gradient-to-br from-red-500 to-red-600'
              : 'bg-gradient-to-br from-rose-500 to-rose-600'
        ]"
      >
        <span class="i-lucide-file-signature text-white text-xl" />
      </div>

      <!-- Conteúdo principal -->
      <div class="flex-1 min-w-0">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="font-semibold text-slate-900 dark:text-white truncate group-hover:text-rose-600 dark:group-hover:text-rose-500 transition-colors">
              {{ contract.title }}
            </h3>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
              {{ contract.contract_number }}
            </p>
          </div>

          <!-- Status badge -->
          <span
            class="flex-shrink-0 inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full"
            :class="statusConfig.class"
          >
            <span :class="statusConfig.icon" class="text-sm" />
            {{ statusConfig.label }}
          </span>
        </div>

        <!-- Info do contratante -->
        <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
          <div class="flex items-center gap-1.5 text-slate-600 dark:text-slate-300">
            <span class="i-lucide-user text-slate-400 dark:text-slate-500" />
            <span class="truncate max-w-[200px]">{{ contract.contractor_name || 'Sem nome' }}</span>
          </div>
          
          <div v-if="contract.contractor_email" class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400">
            <span class="i-lucide-mail text-slate-400 dark:text-slate-500" />
            <span class="truncate max-w-[180px]">{{ contract.contractor_email }}</span>
          </div>

          <div v-if="contract.plan_value" class="flex items-center gap-1.5 text-slate-600 dark:text-slate-300 font-medium">
            <span class="i-lucide-banknote text-slate-400 dark:text-slate-500" />
            {{ formatCurrency(contract.plan_value) }}
          </div>
        </div>

        <!-- Footer com datas e progresso -->
        <div class="mt-4 pt-3 border-t border-slate-100 dark:border-slate-700 flex items-center justify-between">
          <div class="flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400">
            <span class="flex items-center gap-1">
              <span class="i-lucide-calendar" />
              Criado: {{ formatDate(contract.created_at) }}
            </span>
            
            <span v-if="contract.sent_at" class="flex items-center gap-1">
              <span class="i-lucide-send" />
              Enviado: {{ formatDate(contract.sent_at) }}
            </span>

            <span v-if="contract.signed_at" class="flex items-center gap-1 text-green-600 dark:text-green-500">
              <span class="i-lucide-check-circle" />
              Assinado: {{ formatDate(contract.signed_at) }}
            </span>
          </div>

          <!-- Progresso de assinaturas -->
          <div v-if="signatureProgress.total > 0" class="flex items-center gap-2">
            <div class="w-20 h-1.5 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
              <div
                class="h-full rounded-full transition-all duration-500"
                :class="[
                  signatureProgress.percentage === 100 
                    ? 'bg-green-500' 
                    : 'bg-rose-500'
                ]"
                :style="{ width: `${signatureProgress.percentage}%` }"
              />
            </div>
            <span class="text-xs font-medium text-slate-500 dark:text-slate-400">
              {{ signatureProgress.signed }}/{{ signatureProgress.total }}
            </span>
          </div>
        </div>
      </div>

      <!-- Seta de navegação -->
      <div class="flex-shrink-0 self-center">
        <span class="i-lucide-chevron-right text-xl text-slate-300 dark:text-slate-600 group-hover:text-rose-500 group-hover:translate-x-1 transition-all duration-300" />
      </div>
    </div>
  </div>
</template>
