<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI from 'dashboard/api/contracts';
import ContractTimeline from './components/ContractTimeline.vue';

const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { showAlert } = useAlert();

// Estado
const contract = ref(null);
const isLoading = ref(true);
const isActioning = ref(false);

// ID do contrato
const contractId = computed(() => route.params.contractId);

// Status badge
const statusConfig = computed(() => {
  if (!contract.value) return {};
  
  const configs = {
    draft: { label: 'Rascunho', class: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300', icon: 'i-lucide-file-edit' },
    pending: { label: 'Aguardando Assinatura', class: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400', icon: 'i-lucide-clock' },
    partially_signed: { label: 'Parcialmente Assinado', class: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400', icon: 'i-lucide-edit-3' },
    signed: { label: 'Assinado', class: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400', icon: 'i-lucide-check-circle' },
    refused: { label: 'Recusado', class: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400', icon: 'i-lucide-x-circle' },
    expired: { label: 'Expirado', class: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400', icon: 'i-lucide-clock' },
    cancelled: { label: 'Cancelado', class: 'bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-400', icon: 'i-lucide-ban' },
  };
  
  return configs[contract.value.status] || configs.draft;
});

// Carregar contrato
const loadContract = async () => {
  isLoading.value = true;
  try {
    const response = await ContractsAPI.get(contractId.value);
    contract.value = response.data.data;
  } catch (error) {
    console.error('Erro ao carregar contrato:', error);
    showAlert('Erro ao carregar contrato');
    router.push(accountScopedRoute('contracts_list'));
  } finally {
    isLoading.value = false;
  }
};

// Editar contrato
const editContract = () => {
  router.push(accountScopedRoute('contracts_edit', { contractId: contractId.value }));
};

// Enviar para assinatura
const sendForSignature = async () => {
  if (!confirm('Deseja enviar este contrato para assinatura?')) return;
  
  isActioning.value = true;
  try {
    await ContractsAPI.sendForSignature(contractId.value);
    showAlert('Contrato enviado para assinatura!');
    loadContract();
  } catch (error) {
    console.error('Erro ao enviar contrato:', error);
    showAlert('Erro ao enviar contrato para assinatura');
  } finally {
    isActioning.value = false;
  }
};

// Cancelar contrato
const cancelContract = async () => {
  const reason = prompt('Motivo do cancelamento (opcional):');
  if (reason === null) return;
  
  isActioning.value = true;
  try {
    await ContractsAPI.cancel(contractId.value, reason);
    showAlert('Contrato cancelado');
    loadContract();
  } catch (error) {
    console.error('Erro ao cancelar contrato:', error);
    showAlert('Erro ao cancelar contrato');
  } finally {
    isActioning.value = false;
  }
};

// Duplicar contrato
const duplicateContract = async () => {
  isActioning.value = true;
  try {
    const response = await ContractsAPI.duplicate(contractId.value);
    showAlert('Contrato duplicado!');
    router.push(accountScopedRoute('contracts_view', { contractId: response.data.data.id }));
  } catch (error) {
    console.error('Erro ao duplicar contrato:', error);
    showAlert('Erro ao duplicar contrato');
  } finally {
    isActioning.value = false;
  }
};

// Copiar link de assinatura
const copySignatureLink = async (signer) => {
  const baseUrl = window.location.origin;
  const link = `${baseUrl}${signer.signature_url}`;
  
  try {
    await navigator.clipboard.writeText(link);
    showAlert('Link copiado para a área de transferência!');
  } catch (error) {
    console.error('Erro ao copiar link:', error);
    prompt('Copie o link abaixo:', link);
  }
};

// Reenviar para signatário
const resendToSigner = async (signer) => {
  isActioning.value = true;
  try {
    await ContractsAPI.resendToSigner(contractId.value, signer.id);
    showAlert(`Lembrete enviado para ${signer.name}`);
    loadContract();
  } catch (error) {
    console.error('Erro ao reenviar:', error);
    showAlert('Erro ao reenviar lembrete');
  } finally {
    isActioning.value = false;
  }
};

// Voltar
const goBack = () => {
  router.push(accountScopedRoute('contracts_list'));
};

// Formatar data
const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
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

// Signer status config
const getSignerStatus = (signer) => {
  const configs = {
    pending: { label: 'Pendente', class: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400' },
    viewed: { label: 'Visualizou', class: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400' },
    signed: { label: 'Assinou', class: 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400' },
    refused: { label: 'Recusou', class: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400' },
  };
  return configs[signer.status] || configs.pending;
};

// Carregar ao montar
onMounted(() => {
  loadContract();
});
</script>

<template>
  <div class="flex flex-col h-full bg-slate-50 dark:bg-slate-900">
    <!-- Header -->
    <header class="px-8 py-5 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <button
            class="p-2 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
            @click="goBack"
          >
            <span class="i-lucide-arrow-left text-xl" />
          </button>
          <div v-if="contract">
            <div class="flex items-center gap-3">
              <h1 class="text-xl font-bold text-slate-900 dark:text-white">
                {{ contract.title }}
              </h1>
              <span
                class="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-full"
                :class="statusConfig.class"
              >
                <span :class="statusConfig.icon" class="text-sm" />
                {{ statusConfig.label }}
              </span>
            </div>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
              {{ contract.contract_number }} • Criado em {{ formatDate(contract.created_at) }}
            </p>
          </div>
        </div>

        <div v-if="contract" class="flex items-center gap-2">
          <!-- Ações baseadas no status -->
          <template v-if="contract.status === 'draft'">
            <button
              class="px-4 py-2 text-slate-600 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
              @click="editContract"
            >
              <span class="i-lucide-edit mr-2" />
              Editar
            </button>
            <button
              class="px-4 py-2 bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-700 hover:to-rose-800 text-white font-medium rounded-lg shadow-lg shadow-rose-500/25 transition-all disabled:opacity-50"
              :disabled="!contract.signers?.length || isActioning"
              @click="sendForSignature"
            >
              <span class="i-lucide-send mr-2" />
              Enviar para Assinatura
            </button>
          </template>

          <template v-if="['pending', 'partially_signed'].includes(contract.status)">
            <button
              class="px-4 py-2 text-red-600 font-medium rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors disabled:opacity-50"
              :disabled="isActioning"
              @click="cancelContract"
            >
              <span class="i-lucide-x-circle mr-2" />
              Cancelar
            </button>
          </template>

          <button
            class="px-4 py-2 text-slate-600 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors disabled:opacity-50"
            :disabled="isActioning"
            @click="duplicateContract"
          >
            <span class="i-lucide-copy mr-2" />
            Duplicar
          </button>
        </div>
      </div>
    </header>

    <!-- Loading -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="flex flex-col items-center gap-4">
        <div class="relative">
          <div class="w-12 h-12 rounded-full border-4 border-slate-200 dark:border-slate-700" />
          <div class="absolute inset-0 w-12 h-12 rounded-full border-4 border-rose-600 border-t-transparent animate-spin" />
        </div>
        <p class="text-sm text-slate-500 dark:text-slate-400">Carregando contrato...</p>
      </div>
    </div>

    <!-- Content -->
    <div v-else-if="contract" class="flex-1 overflow-auto">
      <div class="flex gap-6 p-8">
        <!-- Main Content -->
        <div class="flex-1 space-y-6">
          <!-- Preview do Contrato -->
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
            <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
              <h2 class="font-semibold text-slate-900 dark:text-white flex items-center gap-2">
                <span class="i-lucide-file-text text-rose-600" />
                Conteúdo do Contrato
              </h2>
              <button
                class="text-sm text-rose-600 hover:text-rose-700 font-medium"
                onclick="window.print()"
              >
                <span class="i-lucide-printer mr-1" />
                Imprimir
              </button>
            </div>
            <div class="p-8 prose prose-sm max-w-none dark:prose-invert" v-html="contract.content_html" />
          </div>
        </div>

        <!-- Sidebar -->
        <div class="w-96 flex-shrink-0 space-y-6">
          <!-- Dados do Contratante -->
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h3 class="font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <span class="i-lucide-user text-rose-600" />
              Contratante
            </h3>
            <dl class="space-y-3 text-sm">
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Nome</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.contractor_name || '-' }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">E-mail</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.contractor_email || '-' }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Telefone</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.contractor_phone || '-' }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">CPF</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.contractor_cpf || '-' }}</dd>
              </div>
            </dl>
          </div>

          <!-- Dados do Plano -->
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h3 class="font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <span class="i-lucide-package text-rose-600" />
              Plano
            </h3>
            <dl class="space-y-3 text-sm">
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Plano</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.plan_name || '-' }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Duração</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.plan_duration || '-' }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Valor</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ formatCurrency(contract.plan_value) }}</dd>
              </div>
              <div>
                <dt class="text-slate-500 dark:text-slate-400">Parcelas</dt>
                <dd class="font-medium text-slate-900 dark:text-white">{{ contract.installments_count || '-' }}x</dd>
              </div>
            </dl>
          </div>

          <!-- Signatários -->
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h3 class="font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <span class="i-lucide-pen-tool text-rose-600" />
              Signatários
              <span class="ml-auto text-xs font-normal text-slate-500">
                {{ contract.signature_progress?.signed || 0 }}/{{ contract.signature_progress?.total || 0 }}
              </span>
            </h3>
            
            <div v-if="contract.signers?.length" class="space-y-3">
              <div
                v-for="signer in contract.signers"
                :key="signer.id"
                class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700"
              >
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <p class="font-medium text-slate-900 dark:text-white text-sm">
                      {{ signer.name }}
                    </p>
                    <p class="text-xs text-slate-500 dark:text-slate-400">
                      {{ signer.email }}
                    </p>
                    <p class="text-xs text-slate-400 dark:text-slate-500 mt-1">
                      {{ signer.role_label }}
                    </p>
                  </div>
                  <span
                    class="px-2 py-0.5 text-xs font-medium rounded-full"
                    :class="getSignerStatus(signer).class"
                  >
                    {{ getSignerStatus(signer).label }}
                  </span>
                </div>
                
                <!-- Ações do signatário -->
                <div v-if="['pending', 'viewed'].includes(signer.status) && contract.status !== 'draft'" class="mt-3 flex gap-2">
                  <button
                    class="flex-1 px-3 py-1.5 text-xs font-medium text-rose-600 bg-rose-50 dark:bg-rose-900/20 rounded-lg hover:bg-rose-100 dark:hover:bg-rose-900/30 transition-colors"
                    @click="copySignatureLink(signer)"
                  >
                    <span class="i-lucide-link mr-1" />
                    Copiar Link
                  </button>
                  <button
                    class="flex-1 px-3 py-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-slate-700 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-600 transition-colors disabled:opacity-50"
                    :disabled="isActioning"
                    @click="resendToSigner(signer)"
                  >
                    <span class="i-lucide-send mr-1" />
                    Reenviar
                  </button>
                </div>

                <!-- Info de assinatura -->
                <div v-if="signer.status === 'signed' && signer.signature" class="mt-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                  <p class="text-xs text-slate-500 dark:text-slate-400">
                    <span class="i-lucide-check-circle text-green-500 mr-1" />
                    Assinado em {{ formatDate(signer.signed_at) }}
                  </p>
                  <p class="text-xs text-slate-400 dark:text-slate-500 mt-1 font-mono truncate">
                    IP: {{ signer.signature.ip_address }}
                  </p>
                </div>

                <!-- Motivo recusa -->
                <div v-if="signer.status === 'refused' && signer.refusal_reason" class="mt-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                  <p class="text-xs text-red-600 dark:text-red-400">
                    <span class="i-lucide-x-circle mr-1" />
                    Motivo: {{ signer.refusal_reason }}
                  </p>
                </div>
              </div>
            </div>
            
            <p v-else class="text-sm text-slate-500 dark:text-slate-400 text-center py-4">
              Nenhum signatário adicionado
            </p>
          </div>

          <!-- Timeline -->
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h3 class="font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <span class="i-lucide-activity text-rose-600" />
              Histórico
            </h3>
            <ContractTimeline :activities="contract.activities || []" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
