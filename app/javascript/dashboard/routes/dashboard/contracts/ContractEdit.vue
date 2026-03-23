<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI from 'dashboard/api/contracts';
import ContractForm from './components/ContractForm.vue';
import ContractEditor from './components/ContractEditor.vue';
import ContractSigners from './components/ContractSigners.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const showAlert = useAlert;

const currentStep = ref(1);
const isLoading = ref(true);
const isSaving = ref(false);
const contractId = computed(() => route.params.contractId);

const contractData = reactive({
  title: '', contractor_name: '', contractor_cpf: '', contractor_rg: '',
  contractor_address: '', contractor_neighborhood: '', contractor_city: '',
  contractor_cep: '', contractor_state: '', contractor_email: '',
  contractor_phone: '', contractor_birth_date: '', plan_name: '',
  plan_duration: '', sessions_call_estrategica: 0, sessions_individual: 0,
  sessions_group_consultive: 0, sessions_group_meetings: 0, plan_value: '',
  installments_count: 1, first_installment_value: '', installment_due_day: 10,
  content_html: '', contract_signers_attributes: [],
});

const steps = [
  { number: 1, title: 'Contratante' },
  { number: 2, title: 'Plano' },
  { number: 3, title: 'Contrato' },
  { number: 4, title: 'Signatários' },
];

const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1: return !!(contractData.contractor_name && contractData.contractor_cpf && contractData.contractor_email && contractData.contractor_phone && contractData.contractor_address && contractData.contractor_city && contractData.contractor_state);
    case 2: return !!(contractData.plan_name && contractData.plan_duration && contractData.plan_value && contractData.installments_count);
    case 3: return !!contractData.content_html;
    case 4: return contractData.contract_signers_attributes.length > 0;
    default: return false;
  }
});

const loadContract = async () => {
  isLoading.value = true;
  try {
    const response = await ContractsAPI.get(contractId.value);
    const data = response.data.data;
    if (data.status !== 'draft') {
      showAlert('Este contrato não pode mais ser editado');
      router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
      return;
    }
    Object.keys(contractData).forEach(key => {
      if (key === 'contract_signers_attributes') {
        contractData[key] = data.signers?.map(s => ({ id: s.id, name: s.name, email: s.email, role: s.role })) || [];
      } else if (data[key] !== undefined) {
        contractData[key] = data[key];
      }
    });
  } catch {
    showAlert('Erro ao carregar contrato');
    router.push(accountScopedRoute('contracts_list'));
  } finally {
    isLoading.value = false;
  }
};

const nextStep = () => { if (currentStep.value < 4) currentStep.value++; };
const prevStep = () => { if (currentStep.value > 1) currentStep.value--; };
const goToStep = step => { if (step <= currentStep.value || isStepValid.value) currentStep.value = step; };

const saveContract = async () => {
  isSaving.value = true;
  try {
    await ContractsAPI.update(contractId.value, { ...contractData });
    showAlert('Contrato atualizado!');
    router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
  } catch {
    showAlert('Erro ao salvar contrato.');
  } finally {
    isSaving.value = false;
  }
};

const cancel = () => router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
const updateSigners = signers => { contractData.contract_signers_attributes = signers; };

onMounted(() => loadContract());
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-surface-1">
    <header class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <button class="p-1.5 rounded-lg text-n-slate-11 hover:bg-n-alpha-3" @click="cancel">
          <span class="i-lucide-arrow-left text-lg" />
        </button>
        <div>
          <h1 class="text-lg font-medium text-n-slate-12">Editar Contrato</h1>
          <p class="text-sm text-n-slate-11">{{ contractData.title || 'Carregando...' }}</p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <Button label="Cancelar" variant="faded" color="slate" size="sm" @click="cancel" />
        <Button v-if="currentStep === 4" label="Salvar Alterações" color="blue" size="sm" :is-loading="isSaving" :disabled="!isStepValid || isSaving" @click="saveContract" />
      </div>
    </header>

    <div class="flex items-center justify-center gap-2 px-6 py-4 border-b border-n-weak">
      <template v-for="(step, index) in steps" :key="step.number">
        <button class="flex items-center gap-2" @click="goToStep(step.number)">
          <div class="flex items-center justify-center w-8 h-8 rounded-full text-sm" :class="[currentStep === step.number ? 'bg-n-brand text-white' : currentStep > step.number ? 'bg-n-teal-9 text-white' : 'bg-n-alpha-3 text-n-slate-11']">
            <span v-if="currentStep > step.number" class="i-lucide-check text-sm" />
            <span v-else>{{ step.number }}</span>
          </div>
          <span class="text-sm hidden sm:inline" :class="currentStep >= step.number ? 'text-n-slate-12 font-medium' : 'text-n-slate-11'">{{ step.title }}</span>
        </button>
        <div v-if="index < steps.length - 1" class="w-8 h-px mx-1" :class="currentStep > step.number ? 'bg-n-teal-9' : 'bg-n-weak'" />
      </template>
    </div>

    <div class="flex-1 overflow-auto">
      <div class="max-w-3xl mx-auto px-6 py-6">
        <div v-if="isLoading" class="flex items-center justify-center py-16"><Spinner /></div>

        <div v-else-if="currentStep === 1" class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
          <h2 class="text-base font-medium text-n-slate-12 mb-4">Dados do Contratante</h2>
          <ContractForm v-model="contractData" section="contractor" />
        </div>

        <div v-else-if="currentStep === 2" class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
          <h2 class="text-base font-medium text-n-slate-12 mb-4">Dados do Plano</h2>
          <ContractForm v-model="contractData" section="plan" />
        </div>

        <div v-else-if="currentStep === 3">
          <ContractEditor v-model="contractData.content_html" :title="contractData.title" @update:title="contractData.title = $event" />
        </div>

        <div v-else-if="currentStep === 4" class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
          <h2 class="text-base font-medium text-n-slate-12 mb-4">Signatários</h2>
          <ContractSigners :signers="contractData.contract_signers_attributes" :contractor-name="contractData.contractor_name" :contractor-email="contractData.contractor_email" @update:signers="updateSigners" />
        </div>
      </div>
    </div>

    <footer class="flex items-center justify-between px-6 py-3 border-t border-n-weak">
      <Button v-if="currentStep > 1" label="Voltar" icon="i-lucide-arrow-left" variant="faded" color="slate" size="sm" @click="prevStep" />
      <div v-else />
      <div class="flex items-center gap-3">
        <span class="text-xs text-n-slate-11">Passo {{ currentStep }} de {{ steps.length }}</span>
        <Button v-if="currentStep < 4" label="Próximo" trailing-icon icon="i-lucide-arrow-right" color="blue" size="sm" :disabled="!isStepValid" @click="nextStep" />
      </div>
    </footer>
  </div>
</template>
