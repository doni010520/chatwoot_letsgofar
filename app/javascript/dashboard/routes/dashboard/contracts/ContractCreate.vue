<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI, { ContractTemplates } from 'dashboard/api/contracts';
import ContractForm from './components/ContractForm.vue';
import ContractEditor from './components/ContractEditor.vue';
import ContractSigners from './components/ContractSigners.vue';

const router = useRouter();
const { accountScopedRoute } = useAccount();
const { showAlert } = useAlert();

// Estado do wizard
const currentStep = ref(1);
const isLoading = ref(false);
const isSaving = ref(false);

// Template carregado
const template = ref(null);

// Dados do contrato
const contractData = reactive({
  title: 'Contrato de Prestação de Serviços - Assessoria de Inglês',
  // Dados do contratante
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
  // Dados do plano
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
  // Conteúdo
  content_html: '',
  // Signatários
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

// Carregar template padrão
const loadTemplate = async () => {
  isLoading.value = true;
  try {
    const response = await ContractTemplates.getDefault();
    template.value = response.data.data;
  } catch (error) {
    console.error('Erro ao carregar template:', error);
    showAlert('Erro ao carregar template do contrato');
  } finally {
    isLoading.value = false;
  }
};

// Aplicar variáveis ao template
const applyVariables = () => {
  if (!template.value?.content_html) return;

  let html = template.value.content_html;

  // Substituir placeholders
  const variables = {
    contractor_name: contractData.contractor_name,
    contractor_cpf: contractData.contractor_cpf,
    contractor_rg: contractData.contractor_rg || '-',
    contractor_address: contractData.contractor_address,
    contractor_neighborhood: contractData.contractor_neighborhood,
    contractor_city: contractData.contractor_city,
    contractor_state: contractData.contractor_state,
    contractor_cep: contractData.contractor_cep,
    contractor_email: contractData.contractor_email,
    contractor_phone: contractData.contractor_phone,
    contractor_birth_date: contractData.contractor_birth_date 
      ? new Date(contractData.contractor_birth_date).toLocaleDateString('pt-BR')
      : '-',
    plan_name: contractData.plan_name,
    plan_duration: contractData.plan_duration,
    sessions_call_estrategica: contractData.sessions_call_estrategica || 0,
    sessions_individual: contractData.sessions_individual || 0,
    sessions_group_consultive: contractData.sessions_group_consultive || 0,
    sessions_group_meetings: contractData.sessions_group_meetings || 0,
    plan_value: contractData.plan_value 
      ? parseFloat(contractData.plan_value).toLocaleString('pt-BR', { minimumFractionDigits: 2 })
      : '0,00',
    installments_count: contractData.installments_count || 1,
    first_installment_value: contractData.first_installment_value || contractData.plan_value,
    installment_due_day: contractData.installment_due_day || 10,
  };

  Object.entries(variables).forEach(([key, value]) => {
    const regex = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
    html = html.replace(regex, value?.toString() || '');
  });

  contractData.content_html = html;
};

// Navegação
const nextStep = () => {
  if (currentStep.value === 2) {
    applyVariables();
  }
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
  if (step < currentStep.value || isStepValid.value) {
    if (step === 3 && currentStep.value === 2) {
      applyVariables();
    }
    currentStep.value = step;
  }
};

// Salvar contrato
const saveContract = async (asDraft = true) => {
  isSaving.value = true;
  try {
    const response = await ContractsAPI.create({
      ...contractData,
      title: contractData.title || `Contrato - ${contractData.contractor_name}`,
    });

    const contract = response.data.data;

    showAlert(asDraft ? 'Rascunho salvo com sucesso!' : 'Contrato criado com sucesso!');
    router.push(accountScopedRoute('contracts_view', { contractId: contract.id }));
  } catch (error) {
    console.error('Erro ao salvar contrato:', error);
    showAlert('Erro ao salvar contrato. Verifique os dados e tente novamente.');
  } finally {
    isSaving.value = false;
  }
};

// Cancelar
const cancel = () => {
  router.push(accountScopedRoute('contracts_list'));
};

// Atualizar signatários
const updateSigners = (signers) => {
  contractData.contract_signers_attributes = signers;
};

// Carregar ao montar
onMounted(() => {
  loadTemplate();
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
              Novo Contrato
            </h1>
            <p class="text-sm text-slate-500 dark:text-slate-400">
              Preencha os dados para gerar o contrato
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
            @click="saveContract(false)"
          >
            <span v-if="isSaving" class="i-lucide-loader-2 animate-spin mr-2" />
            {{ isSaving ? 'Salvando...' : 'Criar Contrato' }}
          </button>
        </div>
      </div>
    </header>

    <!-- Steps Indicator -->
    <div class="px-8 py-6 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
      <div class="flex items-center justify-between max-w-3xl mx-auto">
        <template v-for="(step, index) in steps" :key="step.number">
          <!-- Step -->
          <button
            class="flex items-center gap-3 group"
            :class="{ 'cursor-pointer': step.number <= currentStep || isStepValid }"
            @click="goToStep(step.number)"
          >
            <div
              class="flex items-center justify-center w-10 h-10 rounded-full transition-all duration-300"
              :class="[
                currentStep === step.number
                  ? 'bg-rose-600 text-white shadow-lg shadow-rose-500/30'
                  : currentStep > step.number
                    ? 'bg-green-500 text-white'
                    : 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400'
              ]"
            >
              <span v-if="currentStep > step.number" class="i-lucide-check text-lg" />
              <span v-else :class="step.icon" class="text-lg" />
            </div>
            <div class="hidden sm:block text-left">
              <p
                class="text-sm font-medium transition-colors"
                :class="[
                  currentStep === step.number
                    ? 'text-rose-600 dark:text-rose-500'
                    : currentStep > step.number
                      ? 'text-green-600 dark:text-green-500'
                      : 'text-slate-500 dark:text-slate-400'
                ]"
              >
                Passo {{ step.number }}
              </p>
              <p
                class="text-sm"
                :class="[
                  currentStep >= step.number
                    ? 'text-slate-900 dark:text-white font-medium'
                    : 'text-slate-400 dark:text-slate-500'
                ]"
              >
                {{ step.title }}
              </p>
            </div>
          </button>

          <!-- Connector -->
          <div
            v-if="index < steps.length - 1"
            class="flex-1 h-0.5 mx-4 rounded-full transition-colors duration-300"
            :class="currentStep > step.number ? 'bg-green-500' : 'bg-slate-200 dark:bg-slate-700'"
          />
        </template>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div class="max-w-4xl mx-auto px-8 py-8">
        <!-- Loading -->
        <div v-if="isLoading" class="flex items-center justify-center h-64">
          <div class="flex flex-col items-center gap-4">
            <div class="relative">
              <div class="w-12 h-12 rounded-full border-4 border-slate-200 dark:border-slate-700" />
              <div class="absolute inset-0 w-12 h-12 rounded-full border-4 border-rose-600 border-t-transparent animate-spin" />
            </div>
            <p class="text-sm text-slate-500 dark:text-slate-400">Carregando template...</p>
          </div>
        </div>

        <!-- Step 1: Dados do Contratante -->
        <div v-else-if="currentStep === 1">
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h2 class="text-lg font-semibold text-slate-900 dark:text-white mb-6 flex items-center gap-2">
              <span class="i-lucide-user text-rose-600" />
              Dados do Contratante
            </h2>
            <ContractForm
              v-model="contractData"
              section="contractor"
            />
          </div>
        </div>

        <!-- Step 2: Dados do Plano -->
        <div v-else-if="currentStep === 2">
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h2 class="text-lg font-semibold text-slate-900 dark:text-white mb-6 flex items-center gap-2">
              <span class="i-lucide-package text-rose-600" />
              Dados do Plano
            </h2>
            <ContractForm
              v-model="contractData"
              section="plan"
            />
          </div>
        </div>

        <!-- Step 3: Revisar Contrato -->
        <div v-else-if="currentStep === 3">
          <ContractEditor
            v-model="contractData.content_html"
            :title="contractData.title"
            @update:title="contractData.title = $event"
          />
        </div>

        <!-- Step 4: Signatários -->
        <div v-else-if="currentStep === 4">
          <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 p-6">
            <h2 class="text-lg font-semibold text-slate-900 dark:text-white mb-6 flex items-center gap-2">
              <span class="i-lucide-pen-tool text-rose-600" />
              Signatários
            </h2>
            <ContractSigners
              :signers="contractData.contract_signers_attributes"
              :contractor-name="contractData.contractor_name"
              :contractor-email="contractData.contractor_email"
              @update:signers="updateSigners"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Footer Navigation -->
    <footer class="px-8 py-4 bg-white dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700">
      <div class="max-w-4xl mx-auto flex items-center justify-between">
        <button
          v-if="currentStep > 1"
          class="flex items-center gap-2 px-4 py-2 text-slate-600 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
          @click="prevStep"
        >
          <span class="i-lucide-arrow-left" />
          Voltar
        </button>
        <div v-else />

        <div class="flex items-center gap-3">
          <span class="text-sm text-slate-500 dark:text-slate-400">
            Passo {{ currentStep }} de {{ steps.length }}
          </span>
          
          <button
            v-if="currentStep < 4"
            class="flex items-center gap-2 px-5 py-2 bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-700 hover:to-rose-800 text-white font-medium rounded-lg shadow-lg shadow-rose-500/25 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!isStepValid"
            @click="nextStep"
          >
            Próximo
            <span class="i-lucide-arrow-right" />
          </button>
        </div>
      </div>
    </footer>
  </div>
</template>
