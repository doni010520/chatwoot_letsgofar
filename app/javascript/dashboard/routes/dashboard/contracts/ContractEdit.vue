<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI from 'dashboard/api/contracts';
import ContractForm from './components/ContractForm.vue';
import ContractEditor from './components/ContractEditor.vue';
import ContractSigners from './components/ContractSigners.vue';

const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { showAlert } = useAlert();

// Estado do wizard
const currentStep = ref(1);
const isLoading = ref(true);
const isSaving = ref(false);

// ID do contrato
const contractId = computed(() => route.params.contractId);

// Dados do contrato
const contractData = reactive({
  title: '',
  contractor_name: '',
  contractor_cpf: '',
  contractor_rg: '',
  contractor_address: '',
  contractor_neighborhood: '',
  contractor_city: '',
  contractor_cep: '',
  contractor_state: '',
  contractor_email: '',
  contractor_phone: '',
  contractor_birth_date: '',
  plan_name: '',
  plan_duration: '',
  sessions_call_estrategica: 0,
  sessions_individual: 0,
  sessions_group_consultive: 0,
  sessions_group_meetings: 0,
  plan_value: '',
  installments_count: 1,
  first_installment_value: '',
  installment_due_day: 10,
  content_html: '',
  contract_signers_attributes: [],
});

// Steps do wizard
const steps = [
  { number: 1, title: 'Dados do Contratante', icon: 'i-lucide-user' },
  { number: 2, title: 'Dados do Plano', icon: 'i-lucide-package' },
  { number: 3, title: 'Revisar Contrato', icon: 'i-lucide-file-text' },
  { number: 4, title: 'Signatários', icon: 'i-lucide-pen-tool' },
];

// Validação por step
const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1:
      return !!(
        contractData.contractor_name &&
        contractData.contractor_cpf &&
        contractData.contractor_email &&
        contractData.contractor_phone &&
        contractData.contractor_address &&
        contractData.contractor_city &&
        contractData.contractor_state
      );
    case 2:
      return !!(
        contractData.plan_name &&
        contractData.plan_duration &&
        contractData.plan_value &&
        contractData.installments_count
      );
    case 3:
      return !!contractData.content_html;
    case 4:
      return contractData.contract_signers_attributes.length > 0;
    default:
      return false;
  }
});

// Carregar contrato existente
const loadContract = async () => {
  isLoading.value = true;
  try {
    const response = await ContractsAPI.get(contractId.value);
    const data = response.data.data;

    // Verificar se pode editar
    if (data.status !== 'draft') {
      showAlert('Este contrato não pode mais ser editado');
      router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
      return;
    }

    // Preencher dados
    Object.keys(contractData).forEach((key) => {
      if (key === 'contract_signers_attributes') {
        contractData[key] = data.signers?.map((s) => ({
          id: s.id,
          name: s.name,
          email: s.email,
          role: s.role,
        })) || [];
      } else if (data[key] !== undefined) {
        contractData[key] = data[key];
      }
    });
  } catch (error) {
    console.error('Erro ao carregar contrato:', error);
    showAlert('Erro ao carregar contrato');
    router.push(accountScopedRoute('contracts_list'));
  } finally {
    isLoading.value = false;
  }
};

// Navegação
const nextStep = () => {
  if (currentStep.value < 4) {
    currentStep.value++;
  }
};

const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--;
  }
};

const goToStep = (step) => {
  if (step <= currentStep.value || isStepValid.value) {
    currentStep.value = step;
  }
};

// Salvar contrato
const saveContract = async () => {
  isSaving.value = true;
  try {
    await ContractsAPI.update(contractId.value, {
      ...contractData,
    });

    showAlert('Contrato atualizado com sucesso!');
    router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
  } catch (error) {
    console.error('Erro ao salvar contrato:', error);
    showAlert('Erro ao salvar contrato. Verifique os dados e tente novamente.');
  } finally {
    isSaving.value = false;
  }
};

// Cancelar
const cancel = () => {
  router.push(accountScopedRoute('contracts_view', { contractId: contractId.value }));
};

// Atualizar signatários
const updateSigners = (signers) => {
  contractData.contract_signers_attributes = signers;
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
            @click="cancel"
          >
            <span class="i-lucide-arrow-left text-xl" />
          </button>
          <div>
            <h1 class="text-xl font-bold text-slate-900 dark:text-white">
              Editar Contrato
            </h1>
            <p class="text-sm text-slate-500 dark:text-slate-400">
              {{ contractData.title || 'Carregando...' }}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <button
            class="px-4 py-2 text-slate-600 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
            @click="cancel"
          >
            Cancelar
          </button>
          <button
            v-if="currentStep === 4"
            class="px-5 py-2 bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-700 hover:to-rose-800 text-white font-medium rounded-lg shadow-lg shadow-rose-500/25 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!isStepValid || isSaving"
            @click="saveContract"
          >
            <span v-if="isSaving" class="i-lucide-loader-2 animate-spin mr-2" />
            {{ isSaving ? 'Salvando...' : 'Salvar Alterações' }}
          </button>
        </div>
      </div>
    </header>

    <!-- Steps Indicator -->
    <div class="px-8 py-6 bg-white dark:bg-slate-800 border
