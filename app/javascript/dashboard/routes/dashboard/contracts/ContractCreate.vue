<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI, { ContractTemplates } from 'dashboard/api/contracts';
import ContactAPI from 'dashboard/api/contacts';
import ContractForm from './components/ContractForm.vue';
import ContractEditor from './components/ContractEditor.vue';
import ContractSigners from './components/ContractSigners.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const router = useRouter();
const route = useRoute();
const { accountScopedRoute } = useAccount();
const showAlert = useAlert;

const currentStep = ref(1);
const isLoading = ref(false);
const isSaving = ref(false);
const template = ref(null);
const templates = ref([]);
const selectedTemplateId = ref(null);
const selectedContact = ref(null);

const contractData = reactive({
  title: 'Contrato de Prestação de Serviços - Assessoria de Inglês',
  contact_id: null,
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
  plan_start_date: '',
  plan_end_date: '',
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

const steps = [
  { number: 1, title: 'Contratante', icon: 'i-lucide-user' },
  { number: 2, title: 'Plano', icon: 'i-lucide-package' },
  { number: 3, title: 'Contrato', icon: 'i-lucide-file-text' },
  { number: 4, title: 'Signatários', icon: 'i-lucide-pen-tool' },
];

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

const onContactSelected = contact => {
  selectedContact.value = contact;
  contractData.contact_id = contact.id;
  contractData.contractor_name = contact.name || '';
  contractData.contractor_email = contact.email || '';
  contractData.contractor_phone = contact.phone_number || '';
  if (contact.custom_attributes) {
    const attrs = contact.custom_attributes;
    if (attrs.cpf) contractData.contractor_cpf = attrs.cpf;
    if (attrs.address) contractData.contractor_address = attrs.address;
    if (attrs.city) contractData.contractor_city = attrs.city;
    if (attrs.state) contractData.contractor_state = attrs.state;
    if (attrs.cep) contractData.contractor_cep = attrs.cep;
    if (attrs.neighborhood) contractData.contractor_neighborhood = attrs.neighborhood;
  }
};

const onContactCleared = () => {
  selectedContact.value = null;
  contractData.contact_id = null;
};

const loadTemplate = async () => {
  isLoading.value = true;
  try {
    const response = await ContractTemplates.getDefault();
    template.value = response.data.data;
  } catch (error) {
    console.error('Erro ao carregar template:', error);
  } finally {
    isLoading.value = false;
  }
};

const selectTemplate = async templateId => {
  if (!templateId) {
    // Revert to default template
    await loadTemplate();
    selectedTemplateId.value = null;
    return;
  }
  isLoading.value = true;
  try {
    const response = await ContractTemplates.get(templateId);
    template.value = response.data.data;
    selectedTemplateId.value = templateId;
  } catch (error) {
    console.error('Erro ao carregar template selecionado:', error);
  } finally {
    isLoading.value = false;
  }
};

const applyVariables = () => {
  if (!template.value?.content_html) return;

  let html = template.value.content_html;
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
    first_installment_value: contractData.first_installment_value
      ? parseFloat(contractData.first_installment_value).toLocaleString('pt-BR', { minimumFractionDigits: 2 })
      : contractData.plan_value
        ? parseFloat(contractData.plan_value).toLocaleString('pt-BR', { minimumFractionDigits: 2 })
        : '0,00',
    installment_due_day: contractData.installment_due_day || 10,
    plan_start_date: contractData.plan_start_date
      ? new Date(contractData.plan_start_date).toLocaleDateString('pt-BR')
      : '-',
    plan_end_date: contractData.plan_end_date
      ? new Date(contractData.plan_end_date).toLocaleDateString('pt-BR')
      : '-',
    contract_date: new Date().toLocaleDateString('pt-BR'),
  };

  Object.entries(variables).forEach(([key, value]) => {
    const regex = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
    html = html.replace(regex, value?.toString() || '');
  });

  contractData.content_html = html;
};

const nextStep = () => {
  if (currentStep.value === 2) applyVariables();
  if (currentStep.value < 4) currentStep.value++;
};

const prevStep = () => {
  if (currentStep.value > 1) currentStep.value--;
};

const goToStep = step => {
  if (step < currentStep.value || isStepValid.value) {
    if (step === 3 && currentStep.value === 2) applyVariables();
    currentStep.value = step;
  }
};

const saveContract = async () => {
  isSaving.value = true;
  try {
    const response = await ContractsAPI.create({
      ...contractData,
      title: contractData.title || `Contrato - ${contractData.contractor_name}`,
    });
    const contract = response.data.data;
    showAlert('Contrato criado com sucesso!');
    router.push(accountScopedRoute('contracts_view', { contractId: contract.id }));
  } catch (error) {
    console.error('Erro ao salvar contrato:', error);
    const serverErrors = error?.response?.data?.errors;
    if (serverErrors) {
      console.error('Erros do servidor:', serverErrors);
      showAlert(`Erro: ${Array.isArray(serverErrors) ? serverErrors.join(', ') : serverErrors}`);
    } else {
      showAlert('Erro ao salvar contrato. Verifique os dados e tente novamente.');
    }
  } finally {
    isSaving.value = false;
  }
};

const cancel = () => {
  router.push(accountScopedRoute('contracts_list'));
};

const updateSigners = signers => {
  contractData.contract_signers_attributes = signers;
};

onMounted(async () => {
  try {
    const tplResponse = await ContractTemplates.list({ active_only: true });
    templates.value = tplResponse.data.data || [];
    if (templates.value.length > 0) {
      await selectTemplate(templates.value[0].id);
    } else {
      loadTemplate();
    }
  } catch (error) {
    console.error('Erro ao carregar lista de templates:', error);
    loadTemplate();
  }
  const contactId = route.query.contact_id;
  if (contactId) {
    try {
      const response = await ContactAPI.show(contactId);
      const contact = response.data;
      onContactSelected(contact);
    } catch (error) {
      console.error('Erro ao carregar contato:', error);
    }
  }
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-surface-1">
    <!-- Header -->
    <header class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <button
          class="p-1.5 rounded-lg text-n-slate-11 hover:bg-n-alpha-3 transition-colors"
          @click="cancel"
        >
          <span class="i-lucide-arrow-left text-lg" />
        </button>
        <div>
          <h1 class="text-lg font-medium text-n-slate-12">Novo Contrato</h1>
          <p class="text-sm text-n-slate-11">Preencha os dados para gerar o contrato</p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <Button
          label="Cancelar"
          variant="faded"
          color="slate"
          size="sm"
          @click="cancel"
        />
        <Button
          v-if="currentStep === 4"
          label="Criar Contrato"
          color="blue"
          size="sm"
          :is-loading="isSaving"
          :disabled="!isStepValid || isSaving"
          @click="saveContract"
        />
      </div>
    </header>

    <!-- Steps Indicator -->
    <div class="flex items-center justify-center gap-2 px-6 py-4 border-b border-n-weak">
      <template v-for="(step, index) in steps" :key="step.number">
        <button
          class="flex items-center gap-2"
          @click="goToStep(step.number)"
        >
          <div
            class="flex items-center justify-center w-8 h-8 rounded-full text-sm transition-colors"
            :class="[
              currentStep === step.number
                ? 'bg-n-brand text-white'
                : currentStep > step.number
                  ? 'bg-n-teal-9 text-white'
                  : 'bg-n-alpha-3 text-n-slate-11'
            ]"
          >
            <span v-if="currentStep > step.number" class="i-lucide-check text-sm" />
            <span v-else>{{ step.number }}</span>
          </div>
          <span
            class="text-sm hidden sm:inline"
            :class="currentStep >= step.number ? 'text-n-slate-12 font-medium' : 'text-n-slate-11'"
          >
            {{ step.title }}
          </span>
        </button>
        <div
          v-if="index < steps.length - 1"
          class="w-8 h-px mx-1"
          :class="currentStep > step.number ? 'bg-n-teal-9' : 'bg-n-weak'"
        />
      </template>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div class="max-w-3xl mx-auto px-6 py-6">
        <!-- Loading -->
        <div v-if="isLoading" class="flex items-center justify-center py-16">
          <Spinner />
        </div>

        <!-- Step 1: Contratante -->
        <div v-else-if="currentStep === 1">
          <div class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
            <h2 class="text-base font-medium text-n-slate-12 mb-4 flex items-center gap-2">
              <span class="i-lucide-user text-n-slate-11" />
              Dados do Contratante
            </h2>
            <ContractForm
              v-model="contractData"
              section="contractor"
              :selected-contact="selectedContact"
              :templates="templates"
              :selected-template-id="selectedTemplateId"
              @template-changed="selectTemplate"
              @contact-selected="onContactSelected"
              @contact-cleared="onContactCleared"
            />
          </div>
        </div>

        <!-- Step 2: Plano -->
        <div v-else-if="currentStep === 2">
          <div class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
            <h2 class="text-base font-medium text-n-slate-12 mb-4 flex items-center gap-2">
              <span class="i-lucide-package text-n-slate-11" />
              Dados do Plano
            </h2>
            <ContractForm v-model="contractData" section="plan" />
          </div>
        </div>

        <!-- Step 3: Contrato -->
        <div v-else-if="currentStep === 3">
          <ContractEditor
            v-model="contractData.content_html"
            :title="contractData.title"
            @update:title="contractData.title = $event"
          />
        </div>

        <!-- Step 4: Signatários -->
        <div v-else-if="currentStep === 4">
          <div class="p-6 rounded-xl bg-n-solid-2 border border-n-weak">
            <h2 class="text-base font-medium text-n-slate-12 mb-4 flex items-center gap-2">
              <span class="i-lucide-pen-tool text-n-slate-11" />
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

    <!-- Footer -->
    <footer class="flex items-center justify-between px-6 py-3 border-t border-n-weak">
      <Button
        v-if="currentStep > 1"
        label="Voltar"
        icon="i-lucide-arrow-left"
        variant="faded"
        color="slate"
        size="sm"
        @click="prevStep"
      />
      <div v-else />

      <div class="flex items-center gap-3">
        <span class="text-xs text-n-slate-11">
          Passo {{ currentStep }} de {{ steps.length }}
        </span>
        <Button
          v-if="currentStep < 4"
          label="Próximo"
          trailing-icon
          icon="i-lucide-arrow-right"
          color="blue"
          size="sm"
          :disabled="!isStepValid"
          @click="nextStep"
        />
      </div>
    </footer>
  </div>
</template>
