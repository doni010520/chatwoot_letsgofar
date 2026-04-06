<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI, { ContractTemplates } from 'dashboard/api/contracts';
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
const template = ref(null);
const contractTemplateId = ref(null);
const originalValues = ref({});

const contractData = reactive({
  title: '', contractor_name: '', contractor_cpf: '', contractor_rg: '',
  contractor_address: '', contractor_neighborhood: '', contractor_city: '',
  contractor_cep: '', contractor_state: '', contractor_email: '',
  contractor_phone: '', contractor_birth_date: '', plan_name: '',
  plan_duration: '', plan_start_date: '', plan_end_date: '',
  sessions_call_estrategica: 0, sessions_individual: 0,
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

// === FUNÇÕES DE FORMATAÇÃO ===
const formatCPF = (v) => {
  if (!v) return '';
  const n = v.toString().replace(/\D/g, '').slice(0, 11);
  if (n.length <= 3) return n;
  if (n.length <= 6) return `${n.slice(0,3)}.${n.slice(3)}`;
  if (n.length <= 9) return `${n.slice(0,3)}.${n.slice(3,6)}.${n.slice(6)}`;
  return `${n.slice(0,3)}.${n.slice(3,6)}.${n.slice(6,9)}-${n.slice(9)}`;
};

const formatCEP = (v) => {
  if (!v) return '';
  const n = v.toString().replace(/\D/g, '').slice(0, 8);
  if (n.length <= 5) return n;
  return `${n.slice(0,5)}-${n.slice(5)}`;
};

const formatPhone = (v) => {
  if (!v) return '';
  const n = v.toString().replace(/\D/g, '').slice(0, 11);
  if (n.length <= 2) return `(${n}`;
  if (n.length <= 7) return `(${n.slice(0,2)}) ${n.slice(2)}`;
  return `(${n.slice(0,2)}) ${n.slice(2,7)}-${n.slice(7)}`;
};

const formatCurrency = (val) => {
  if (!val) return '0,00';
  return parseFloat(val).toLocaleString('pt-BR', { minimumFractionDigits: 2 });
};

const formatDate = (val) => {
  if (!val) return '-';
  return new Date(val).toLocaleDateString('pt-BR');
};

// Remove formatação (apenas dígitos)
const unformat = (v) => {
  if (!v) return '';
  return v.toString().replace(/\D/g, '');
};

const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1: return !!(contractData.contractor_name && contractData.contractor_cpf && contractData.contractor_email && contractData.contractor_phone && contractData.contractor_address && contractData.contractor_city && contractData.contractor_state);
    case 2: return !!(contractData.plan_name && contractData.plan_duration && contractData.plan_value && contractData.installments_count);
    case 3: return !!contractData.content_html;
    case 4: return contractData.contract_signers_attributes.length > 0;
    default: return false;
  }
});

const loadTemplate = async (templateId) => {
  if (!templateId) return;
  try {
    const response = await ContractTemplates.get(templateId);
    template.value = response.data.data;
  } catch (error) {
    console.error('Erro ao carregar template:', error);
  }
};

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
    
    contractTemplateId.value = data.contract_template_id;
    
    Object.keys(contractData).forEach(key => {
      if (key === 'contract_signers_attributes') {
        contractData[key] = data.signers?.map(s => ({ id: s.id, name: s.name, email: s.email, role: s.role })) || [];
      } else if (data[key] !== undefined) {
        contractData[key] = data[key];
      }
    });
    
    // Salvar valores originais - tanto formatados quanto não formatados
    // para conseguir encontrar no HTML independente de como foi salvo
    const cpfRaw = data.contractor_cpf || '';
    const cepRaw = data.contractor_cep || '';
    const phoneRaw = data.contractor_phone || '';
    
    originalValues.value = {
      contractor_name: data.contractor_name || '',
      // CPF: salva ambas versões
      contractor_cpf: cpfRaw,
      contractor_cpf_formatted: formatCPF(cpfRaw),
      contractor_cpf_raw: unformat(cpfRaw),
      // RG
      contractor_rg: data.contractor_rg || '',
      // Endereço
      contractor_address: data.contractor_address || '',
      contractor_neighborhood: data.contractor_neighborhood || '',
      contractor_city: data.contractor_city || '',
      contractor_state: data.contractor_state || '',
      // CEP: salva ambas versões
      contractor_cep: cepRaw,
      contractor_cep_formatted: formatCEP(cepRaw),
      contractor_cep_raw: unformat(cepRaw),
      // Email
      contractor_email: data.contractor_email || '',
      // Telefone: salva ambas versões
      contractor_phone: phoneRaw,
      contractor_phone_formatted: formatPhone(phoneRaw),
      contractor_phone_raw: unformat(phoneRaw),
      // Data nascimento
      contractor_birth_date: data.contractor_birth_date || '',
      // Plano
      plan_name: data.plan_name || '',
      plan_duration: data.plan_duration || '',
      plan_value: data.plan_value || '',
      installments_count: data.installments_count || 1,
      first_installment_value: data.first_installment_value || '',
      installment_due_day: data.installment_due_day || 10,
      plan_start_date: data.plan_start_date || '',
      plan_end_date: data.plan_end_date || '',
      sessions_call_estrategica: data.sessions_call_estrategica || 0,
      sessions_individual: data.sessions_individual || 0,
      sessions_group_consultive: data.sessions_group_consultive || 0,
      sessions_group_meetings: data.sessions_group_meetings || 0,
    };
    
    if (contractTemplateId.value) {
      await loadTemplate(contractTemplateId.value);
    }
  } catch {
    showAlert('Erro ao carregar contrato');
    router.push(accountScopedRoute('contracts_list'));
  } finally {
    isLoading.value = false;
  }
};

// Função auxiliar para substituir valor no HTML (tenta múltiplas variações)
const replaceInHtml = (html, oldVariations, newValue) => {
  let result = html;
  // oldVariations é um array de possíveis valores antigos a procurar
  for (const oldVal of oldVariations) {
    if (oldVal && oldVal.length > 2 && result.includes(oldVal)) {
      const escaped = oldVal.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      result = result.replace(new RegExp(escaped, 'g'), newValue || '');
    }
  }
  return result;
};

// Função para aplicar variáveis ao template OU substituir valores no HTML existente
const applyVariables = () => {
  let html = template.value?.content_html || contractData.content_html;
  
  if (!html) return;

  // Se NÃO tem template, faz substituição dos valores antigos pelos novos
  if (!template.value?.content_html) {
    const orig = originalValues.value;
    
    // Nome
    html = replaceInHtml(html, [orig.contractor_name], contractData.contractor_name);
    
    // CPF - tenta todas as variações (formatado, raw, original)
    const newCpfFormatted = formatCPF(contractData.contractor_cpf);
    html = replaceInHtml(html, [
      orig.contractor_cpf_formatted,
      orig.contractor_cpf,
      orig.contractor_cpf_raw,
    ], newCpfFormatted);
    
    // RG
    html = replaceInHtml(html, [orig.contractor_rg], contractData.contractor_rg || '-');
    
    // Endereço
    html = replaceInHtml(html, [orig.contractor_address], contractData.contractor_address);
    
    // Bairro
    html = replaceInHtml(html, [orig.contractor_neighborhood], contractData.contractor_neighborhood);
    
    // Cidade
    html = replaceInHtml(html, [orig.contractor_city], contractData.contractor_city);
    
    // Estado
    html = replaceInHtml(html, [orig.contractor_state], contractData.contractor_state);
    
    // CEP - tenta todas as variações
    const newCepFormatted = formatCEP(contractData.contractor_cep);
    html = replaceInHtml(html, [
      orig.contractor_cep_formatted,
      orig.contractor_cep,
      orig.contractor_cep_raw,
    ], newCepFormatted);
    
    // Email
    html = replaceInHtml(html, [orig.contractor_email], contractData.contractor_email);
    
    // Telefone - tenta todas as variações
    const newPhoneFormatted = formatPhone(contractData.contractor_phone);
    html = replaceInHtml(html, [
      orig.contractor_phone_formatted,
      orig.contractor_phone,
      orig.contractor_phone_raw,
    ], newPhoneFormatted);
    
    // Data nascimento
    html = replaceInHtml(html, [formatDate(orig.contractor_birth_date)], formatDate(contractData.contractor_birth_date));
    
    // Nome do plano
    html = replaceInHtml(html, [orig.plan_name], contractData.plan_name);
    
    // Duração
    html = replaceInHtml(html, [orig.plan_duration], contractData.plan_duration);
    
    // Valor do plano
    html = replaceInHtml(html, [formatCurrency(orig.plan_value)], formatCurrency(contractData.plan_value));
    
    // Primeira parcela
    html = replaceInHtml(html, 
      [formatCurrency(orig.first_installment_value || orig.plan_value)], 
      formatCurrency(contractData.first_installment_value || contractData.plan_value)
    );
    
    // Data início
    html = replaceInHtml(html, [formatDate(orig.plan_start_date)], formatDate(contractData.plan_start_date));
    
    // Data fim
    html = replaceInHtml(html, [formatDate(orig.plan_end_date)], formatDate(contractData.plan_end_date));
    
    // Atualiza os valores originais para próximas edições
    const cpfNew = contractData.contractor_cpf;
    const cepNew = contractData.contractor_cep;
    const phoneNew = contractData.contractor_phone;
    
    originalValues.value = {
      contractor_name: contractData.contractor_name,
      contractor_cpf: cpfNew,
      contractor_cpf_formatted: formatCPF(cpfNew),
      contractor_cpf_raw: unformat(cpfNew),
      contractor_rg: contractData.contractor_rg,
      contractor_address: contractData.contractor_address,
      contractor_neighborhood: contractData.contractor_neighborhood,
      contractor_city: contractData.contractor_city,
      contractor_state: contractData.contractor_state,
      contractor_cep: cepNew,
      contractor_cep_formatted: formatCEP(cepNew),
      contractor_cep_raw: unformat(cepNew),
      contractor_email: contractData.contractor_email,
      contractor_phone: phoneNew,
      contractor_phone_formatted: formatPhone(phoneNew),
      contractor_phone_raw: unformat(phoneNew),
      contractor_birth_date: contractData.contractor_birth_date,
      plan_name: contractData.plan_name,
      plan_duration: contractData.plan_duration,
      plan_value: contractData.plan_value,
      installments_count: contractData.installments_count,
      first_installment_value: contractData.first_installment_value,
      installment_due_day: contractData.installment_due_day,
      plan_start_date: contractData.plan_start_date,
      plan_end_date: contractData.plan_end_date,
      sessions_call_estrategica: contractData.sessions_call_estrategica,
      sessions_individual: contractData.sessions_individual,
      sessions_group_consultive: contractData.sessions_group_consultive,
      sessions_group_meetings: contractData.sessions_group_meetings,
    };
  } else {
    // Se TEM template, substitui os placeholders {{variavel}}
    const variables = {
      contractor_name: contractData.contractor_name,
      contractor_cpf: formatCPF(contractData.contractor_cpf),
      contractor_rg: contractData.contractor_rg || '-',
      contractor_address: contractData.contractor_address,
      contractor_neighborhood: contractData.contractor_neighborhood,
      contractor_city: contractData.contractor_city,
      contractor_state: contractData.contractor_state,
      contractor_cep: formatCEP(contractData.contractor_cep),
      contractor_email: contractData.contractor_email,
      contractor_phone: formatPhone(contractData.contractor_phone),
      contractor_birth_date: formatDate(contractData.contractor_birth_date),
      plan_name: contractData.plan_name,
      plan_duration: contractData.plan_duration,
      sessions_call_estrategica: contractData.sessions_call_estrategica || 0,
      sessions_individual: contractData.sessions_individual || 0,
      sessions_group_consultive: contractData.sessions_group_consultive || 0,
      sessions_group_meetings: contractData.sessions_group_meetings || 0,
      plan_value: formatCurrency(contractData.plan_value),
      installments_count: contractData.installments_count || 1,
      first_installment_value: formatCurrency(contractData.first_installment_value || contractData.plan_value),
      installment_due_day: contractData.installment_due_day || 10,
      plan_start_date: formatDate(contractData.plan_start_date),
      plan_end_date: formatDate(contractData.plan_end_date),
      contract_date: new Date().toLocaleDateString('pt-BR'),
    };

    Object.entries(variables).forEach(([key, value]) => {
      const regex = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
      html = html.replace(regex, value?.toString() || '');
    });
  }

  contractData.content_html = html;
};

const nextStep = () => {
  // Aplicar variáveis ao avançar do passo 2 para o 3
  if (currentStep.value === 2) {
    applyVariables();
  }
  if (currentStep.value < 4) currentStep.value++;
};

const prevStep = () => { if (currentStep.value > 1) currentStep.value--; };

const goToStep = step => {
  if (step <= currentStep.value || isStepValid.value) {
    // Aplicar variáveis se estiver indo para o passo 3 vindo do passo 2
    if (step === 3 && currentStep.value === 2) {
      applyVariables();
    }
    currentStep.value = step;
  }
};

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
