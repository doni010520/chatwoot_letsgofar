<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI from 'dashboard/api/contracts';
import ContractTimeline from './components/ContractTimeline.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const showAlert = useAlert;

const contract = ref(null);
const isLoading = ref(true);
const isActioning = ref(false);

const contractId = computed(() => route.params.contractId);

const statusConfig = {
  draft: { label: 'Rascunho', class: 'bg-n-slate-3 text-n-slate-11' },
  pending: { label: 'Aguardando', class: 'bg-n-amber-3 text-n-amber-11' },
  partially_signed: { label: 'Parcial', class: 'bg-n-blue-3 text-n-blue-11' },
  signed: { label: 'Assinado', class: 'bg-n-teal-3 text-n-teal-11' },
  refused: { label: 'Recusado', class: 'bg-n-ruby-3 text-n-ruby-11' },
  expired: { label: 'Expirado', class: 'bg-n-slate-3 text-n-slate-11' },
  cancelled: { label: 'Cancelado', class: 'bg-n-slate-3 text-n-slate-11' },
};

const signerStatusConfig = {
  pending: { label: 'Pendente', class: 'bg-n-slate-3 text-n-slate-11' },
  viewed: { label: 'Visualizou', class: 'bg-n-blue-3 text-n-blue-11' },
  signed: { label: 'Assinou', class: 'bg-n-teal-3 text-n-teal-11' },
  refused: { label: 'Recusou', class: 'bg-n-ruby-3 text-n-ruby-11' },
};

const getStatus = s => statusConfig[s] || statusConfig.draft;
const getSignerStatus = s => signerStatusConfig[s.status] || signerStatusConfig.pending;

const formatDate = d => {
  if (!d) return '-';
  return new Date(d).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
};

const formatCurrency = v => {
  if (!v) return '-';
  return parseFloat(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
};

const loadContract = async () => {
  isLoading.value = true;
  try {
    const response = await ContractsAPI.get(contractId.value);
    contract.value = response.data.data;
  } catch (error) {
    showAlert('Erro ao carregar contrato');
    router.push(accountScopedRoute('contracts_list'));
  } finally {
    isLoading.value = false;
  }
};

const editContract = () => router.push(accountScopedRoute('contracts_edit', { contractId: contractId.value }));

const sendForSignature = async () => {
  if (!confirm('Deseja enviar este contrato para assinatura?')) return;
  isActioning.value = true;
  try {
    await ContractsAPI.sendForSignature(contractId.value);
    showAlert('Contrato enviado para assinatura!');
    loadContract();
  } catch (error) {
    showAlert('Erro ao enviar contrato');
  } finally {
    isActioning.value = false;
  }
};

const cancelContract = async () => {
  const reason = prompt('Motivo do cancelamento (opcional):');
  if (reason === null) return;
  isActioning.value = true;
  try {
    await ContractsAPI.cancel(contractId.value, reason);
    showAlert('Contrato cancelado');
    loadContract();
  } catch (error) {
    showAlert('Erro ao cancelar contrato');
  } finally {
    isActioning.value = false;
  }
};

const duplicateContract = async () => {
  isActioning.value = true;
  try {
    const response = await ContractsAPI.duplicate(contractId.value);
    showAlert('Contrato duplicado!');
    router.push(accountScopedRoute('contracts_view', { contractId: response.data.data.id }));
  } catch (error) {
    showAlert('Erro ao duplicar contrato');
  } finally {
    isActioning.value = false;
  }
};

const copySignatureLink = async signer => {
  const link = `${window.location.origin}${signer.signature_url}`;
  try {
    await navigator.clipboard.writeText(link);
    showAlert('Link copiado!');
  } catch {
    prompt('Copie o link:', link);
  }
};

const resendToSigner = async signer => {
  isActioning.value = true;
  try {
    await ContractsAPI.resendToSigner(contractId.value, signer.id);
    showAlert(`Lembrete enviado para ${signer.name}`);
    loadContract();
  } catch {
    showAlert('Erro ao reenviar lembrete');
  } finally {
    isActioning.value = false;
  }
};

const goBack = () => router.push(accountScopedRoute('contracts_list'));

onMounted(() => loadContract());
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-surface-1">
    <!-- Header -->
    <header class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <button class="p-1.5 rounded-lg text-n-slate-11 hover:bg-n-alpha-3" @click="goBack">
          <span class="i-lucide-arrow-left text-lg" />
        </button>
        <div v-if="contract">
          <div class="flex items-center gap-2">
            <h1 class="text-lg font-medium text-n-slate-12">{{ contract.title }}</h1>
            <span class="px-2 py-0.5 text-xs font-medium rounded-full" :class="getStatus(contract.status).class">
              {{ getStatus(contract.status).label }}
            </span>
          </div>
          <p class="text-sm text-n-slate-11">{{ contract.contract_number }}</p>
        </div>
      </div>

      <div v-if="contract" class="flex items-center gap-2">
        <Button v-if="contract.status === 'draft'" label="Editar" icon="i-lucide-pencil" variant="faded" color="slate" size="sm" @click="editContract" />
        <Button v-if="contract.status === 'draft'" label="Enviar para Assinatura" icon="i-lucide-send" color="blue" size="sm" :disabled="!contract.signers?.length || isActioning" @click="sendForSignature" />
        <Button v-if="['pending','partially_signed'].includes(contract.status)" label="Cancelar" icon="i-lucide-x-circle" variant="faded" color="ruby" size="sm" :disabled="isActioning" @click="cancelContract" />
        <Button label="Duplicar" icon="i-lucide-copy" variant="faded" color="slate" size="sm" :disabled="isActioning" @click="duplicateContract" />
      </div>
    </header>

    <!-- Loading -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <Spinner />
    </div>

    <!-- Content -->
    <div v-else-if="contract" class="flex-1 overflow-auto">
      <div class="flex gap-4 p-6">
        <!-- Main -->
        <div class="flex-1 min-w-0">
          <div class="rounded-xl border border-n-weak overflow-hidden">
            <div class="px-6 py-3 border-b border-n-weak flex items-center justify-between bg-n-solid-2">
              <h2 class="text-sm font-medium text-n-slate-12">Conteúdo do Contrato</h2>
              <button class="text-xs text-n-brand hover:underline" onclick="window.print()">Imprimir</button>
            </div>
            <div class="contract-preview-content p-6 prose prose-sm max-w-none" v-html="contract.content_html" />
          </div>
        </div>

        <!-- Sidebar -->
        <div class="w-80 shrink-0 flex flex-col gap-4">
          <!-- Info -->
          <div class="p-4 rounded-xl bg-n-solid-2 border border-n-weak">
            <h3 class="text-sm font-medium text-n-slate-12 mb-3">Informações</h3>
            <dl class="flex flex-col gap-2 text-sm">
              <div><dt class="text-n-slate-11 text-xs">Contratante</dt><dd class="text-n-slate-12">{{ contract.contractor_name || '-' }}</dd></div>
              <div><dt class="text-n-slate-11 text-xs">E-mail</dt><dd class="text-n-slate-12">{{ contract.contractor_email || '-' }}</dd></div>
              <div><dt class="text-n-slate-11 text-xs">Plano</dt><dd class="text-n-slate-12">{{ contract.plan_name || '-' }}</dd></div>
              <div><dt class="text-n-slate-11 text-xs">Valor</dt><dd class="text-n-slate-12">{{ formatCurrency(contract.plan_value) }}</dd></div>
              <div><dt class="text-n-slate-11 text-xs">Criado em</dt><dd class="text-n-slate-12">{{ formatDate(contract.created_at) }}</dd></div>
              <div v-if="contract.sent_at"><dt class="text-n-slate-11 text-xs">Enviado em</dt><dd class="text-n-slate-12">{{ formatDate(contract.sent_at) }}</dd></div>
              <div v-if="contract.signed_at"><dt class="text-n-slate-11 text-xs">Assinado em</dt><dd class="text-n-slate-12">{{ formatDate(contract.signed_at) }}</dd></div>
            </dl>
          </div>

          <!-- Signers -->
          <div class="p-4 rounded-xl bg-n-solid-2 border border-n-weak">
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-sm font-medium text-n-slate-12">Signatários</h3>
              <span class="text-xs text-n-slate-11">
                {{ contract.signature_progress?.signed || 0 }}/{{ contract.signature_progress?.total || 0 }}
              </span>
            </div>
            <div v-if="contract.signers?.length" class="flex flex-col gap-2">
              <div
                v-for="signer in contract.signers"
                :key="signer.id"
                class="p-3 rounded-lg bg-n-alpha-2 border border-n-weak"
              >
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <p class="text-sm font-medium text-n-slate-12">{{ signer.name }}</p>
                    <p class="text-xs text-n-slate-11">{{ signer.email }}</p>
                    <p class="text-xs text-n-slate-10 mt-0.5">{{ signer.role_label }}</p>
                  </div>
                  <span class="px-2 py-0.5 text-xs rounded-full" :class="getSignerStatus(signer).class">
                    {{ getSignerStatus(signer).label }}
                  </span>
                </div>
                <div v-if="['pending','viewed'].includes(signer.status) && contract.status !== 'draft'" class="mt-2 flex gap-2">
                  <button class="flex-1 px-2 py-1 text-xs text-n-brand bg-n-blue-3 rounded hover:bg-n-blue-4 transition-colors" @click="copySignatureLink(signer)">Copiar Link</button>
                  <button class="flex-1 px-2 py-1 text-xs text-n-slate-11 bg-n-alpha-3 rounded hover:bg-n-alpha-4 transition-colors" :disabled="isActioning" @click="resendToSigner(signer)">Reenviar</button>
                </div>
                <p v-if="signer.status === 'signed'" class="text-xs text-n-teal-11 mt-2">Assinado em {{ formatDate(signer.signed_at) }}</p>
                <p v-if="signer.status === 'refused' && signer.refusal_reason" class="text-xs text-n-ruby-11 mt-2">Motivo: {{ signer.refusal_reason }}</p>
              </div>
            </div>
            <p v-else class="text-sm text-n-slate-11 text-center py-3">Nenhum signatário</p>
          </div>

          <!-- Timeline -->
          <div class="p-4 rounded-xl bg-n-solid-2 border border-n-weak">
            <h3 class="text-sm font-medium text-n-slate-12 mb-3">Histórico</h3>
            <ContractTimeline :activities="contract.activities || []" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.contract-preview-content {
  background: #ffffff;
  color: #1a1a1a;
}

.contract-preview-content :deep(*) {
  color: #1a1a1a !important;
}

.contract-preview-content :deep(a) {
  color: #1e40af !important;
}

.contract-preview-content :deep(table) {
  border-collapse: collapse;
  width: 100%;
}

.contract-preview-content :deep(td),
.contract-preview-content :deep(th) {
  border: 1px solid #d1d5db;
  padding: 8px 12px;
  color: #1a1a1a !important;
  background: #ffffff;
}

.contract-preview-content :deep(h1),
.contract-preview-content :deep(h2),
.contract-preview-content :deep(h3),
.contract-preview-content :deep(h4) {
  color: #111827 !important;
}

.contract-preview-content :deep(p) {
  color: #1a1a1a !important;
}
</style>
