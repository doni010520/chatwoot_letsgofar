<script setup>
import { ref, watch } from 'vue';
import ContactAPI from 'dashboard/api/contacts';

const props = defineProps({
  modelValue: { type: Object, required: true },
  section: { type: String, default: 'contractor' },
  selectedContact: { type: Object, default: null },
  templates: { type: Array, default: () => [] },
  selectedTemplateId: { type: [String, Number], default: null },
});

const emit = defineEmits(['update:modelValue', 'contact-selected', 'contact-cleared', 'template-changed']);

// Contact search state
const searchQuery = ref('');
const searchResults = ref([]);
const isSearching = ref(false);
const showDropdown = ref(false);

let searchTimeout = null;

watch(searchQuery, newVal => {
  if (searchTimeout) clearTimeout(searchTimeout);
  if (!newVal || newVal.length < 2) {
    searchResults.value = [];
    showDropdown.value = false;
    return;
  }
  searchTimeout = setTimeout(async () => {
    isSearching.value = true;
    try {
      const response = await ContactAPI.search(newVal);
      searchResults.value = response.data.payload || [];
      showDropdown.value = searchResults.value.length > 0;
    } catch (error) {
      console.error('Erro ao buscar contatos:', error);
      searchResults.value = [];
    } finally {
      isSearching.value = false;
    }
  }, 300);
});

const selectContact = contact => {
  emit('contact-selected', contact);
  searchQuery.value = '';
  searchResults.value = [];
  showDropdown.value = false;
};

const clearContact = () => {
  emit('contact-cleared');
};

const states = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA',
  'MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN',
  'RS','RO','RR','SC','SP','SE','TO',
];

const updateField = (field, value) => {
  // Atualiza diretamente no objeto reactive (mutação direta funciona com reactive)
  props.modelValue[field] = value;
};

const formatCPF = v => {
  if (!v) return '';
  const n = v.replace(/\D/g, '').slice(0, 11);
  if (n.length <= 3) return n;
  if (n.length <= 6) return `${n.slice(0,3)}.${n.slice(3)}`;
  if (n.length <= 9) return `${n.slice(0,3)}.${n.slice(3,6)}.${n.slice(6)}`;
  return `${n.slice(0,3)}.${n.slice(3,6)}.${n.slice(6,9)}-${n.slice(9)}`;
};

const formatPhone = v => {
  if (!v) return '';
  const n = v.replace(/\D/g, '').slice(0, 11);
  if (n.length <= 2) return `(${n}`;
  if (n.length <= 7) return `(${n.slice(0,2)}) ${n.slice(2)}`;
  return `(${n.slice(0,2)}) ${n.slice(2,7)}-${n.slice(7)}`;
};

const formatCEP = v => {
  if (!v) return '';
  const n = v.replace(/\D/g, '').slice(0, 8);
  if (n.length <= 5) return n;
  return `${n.slice(0,5)}-${n.slice(5)}`;
};

const formatCurrency = v => {
  if (!v && v !== 0) return '';
  const str = v.toString().replace(/[^\d]/g, '');
  if (!str) return '';
  const cents = parseInt(str, 10);
  if (isNaN(cents)) return '';
  const reais = cents / 100;
  return reais.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

const parseCurrency = v => {
  if (!v) return 0;
  const str = v.toString().replace(/[^\d]/g, '');
  if (!str) return 0;
  return parseInt(str, 10) / 100;
};

// Format a stored numeric value for display (e.g., 0.40 → "0,40")
const displayCurrency = v => {
  if (!v && v !== 0) return '';
  const n = parseFloat(v);
  if (isNaN(n)) return '';
  return n.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

const handleCPFInput = e => { const f = formatCPF(e.target.value); e.target.value = f; updateField('contractor_cpf', f); };
const handlePhoneInput = e => { const f = formatPhone(e.target.value); e.target.value = f; updateField('contractor_phone', f); };
const handleCEPInput = e => { const f = formatCEP(e.target.value); e.target.value = f; updateField('contractor_cep', f); };
const handleCurrencyInput = (field, e) => { const f = formatCurrency(e.target.value); e.target.value = f; updateField(field, parseCurrency(e.target.value)); };

const inputClass = 'w-full h-10 px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand transition-all';
const labelClass = 'block mb-1 text-sm font-medium text-n-slate-12';
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- Seção: Dados do Contratante -->
    <template v-if="section === 'contractor'">
      <!-- Template Selector -->
      <div v-if="templates.length > 0" class="mb-4">
        <label :class="labelClass">Modelo de Contrato *</label>
        <select
          :value="selectedTemplateId"
          :class="inputClass"
          @change="emit('template-changed', $event.target.value)"
        >
          <option
            v-for="t in templates"
            :key="t.id"
            :value="t.id"
            class="bg-n-solid-3 text-n-slate-12"
          >
            {{ t.name }}
          </option>
        </select>
      </div>

      <!-- Contact Search / Selector -->
      <div class="mb-4 p-4 rounded-lg bg-n-alpha-2 border border-n-weak">
        <label :class="labelClass">Vincular a Contato do CRM</label>

        <!-- Selected contact badge -->
        <div v-if="selectedContact" class="flex items-center gap-2 mt-2">
          <span
            class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-n-teal-3 text-n-teal-11 text-sm font-medium"
          >
            <span class="i-lucide-user-check text-sm" />
            Vinculado: {{ selectedContact.name }}
            <button
              class="ml-1 hover:text-n-teal-12 transition-colors"
              type="button"
              @click="clearContact"
            >
              <span class="i-lucide-x text-sm" />
            </button>
          </span>
        </div>

        <!-- Search input -->
        <div v-else class="relative mt-2">
          <div class="relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-n-slate-10 z-10 pointer-events-none flex items-center">
              <span class="i-lucide-search block w-4 h-4" />
            </span>
            <input
              v-model="searchQuery"
              type="text"
              :class="inputClass"
              style="padding-left: 2.5rem;"
              placeholder="Buscar contato por nome, email ou telefone..."
            />
            <span
              v-if="isSearching"
              class="absolute right-3 top-1/2 -translate-y-1/2"
            >
              <span class="i-lucide-loader-2 text-sm text-n-slate-10 animate-spin" />
            </span>
          </div>

          <!-- Dropdown results -->
          <div
            v-if="showDropdown"
            class="absolute z-50 mt-1 w-full rounded-lg bg-n-solid-2 border border-n-weak shadow-lg max-h-60 overflow-auto"
          >
            <button
              v-for="contact in searchResults"
              :key="contact.id"
              type="button"
              class="w-full px-4 py-3 text-left hover:bg-n-alpha-3 transition-colors border-b border-n-weak last:border-b-0"
              @click="selectContact(contact)"
            >
              <div class="text-sm font-medium text-n-slate-12">{{ contact.name }}</div>
              <div class="flex items-center gap-3 mt-0.5">
                <span v-if="contact.email" class="text-xs text-n-slate-11">{{ contact.email }}</span>
                <span v-if="contact.phone_number" class="text-xs text-n-slate-11">{{ contact.phone_number }}</span>
              </div>
            </button>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">Nome Completo *</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_name"
            placeholder="Nome completo do contratante" @input="updateField('contractor_name', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">CPF *</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_cpf"
            placeholder="000.000.000-00" @input="handleCPFInput" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">RG</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_rg"
            placeholder="Número do RG" @input="updateField('contractor_rg', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Data de Nascimento</label>
          <input type="date" :class="inputClass" :value="modelValue.contractor_birth_date"
            @input="updateField('contractor_birth_date', $event.target.value)" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">E-mail *</label>
          <input type="email" :class="inputClass" :value="modelValue.contractor_email"
            placeholder="email@exemplo.com" @input="updateField('contractor_email', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Telefone *</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_phone"
            placeholder="(00) 00000-0000" @input="handlePhoneInput" />
        </div>
      </div>

      <div>
        <label :class="labelClass">Endereço *</label>
        <input type="text" :class="inputClass" :value="modelValue.contractor_address"
          placeholder="Rua, número, complemento" @input="updateField('contractor_address', $event.target.value)" />
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div>
          <label :class="labelClass">Bairro</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_neighborhood"
            placeholder="Bairro" @input="updateField('contractor_neighborhood', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Cidade *</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_city"
            placeholder="Cidade" @input="updateField('contractor_city', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Estado *</label>
          <select :class="inputClass" class="select-dark" :value="modelValue.contractor_state"
            @change="updateField('contractor_state', $event.target.value)">
            <option value="">UF</option>
            <option v-for="s in states" :key="s" :value="s">{{ s }}</option>
          </select>
        </div>
        <div>
          <label :class="labelClass">CEP</label>
          <input type="text" :class="inputClass" :value="modelValue.contractor_cep"
            placeholder="00000-000" @input="handleCEPInput" />
        </div>
      </div>
    </template>

    <!-- Seção: Dados do Plano -->
    <template v-if="section === 'plan'">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">Nome do Plano *</label>
          <input type="text" :class="inputClass" :value="modelValue.plan_name"
            placeholder="Ex: Plano Premium Anual" @input="updateField('plan_name', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Duração *</label>
          <input type="text" :class="inputClass" :value="modelValue.plan_duration"
            placeholder="Ex: 12 meses" @input="updateField('plan_duration', $event.target.value)" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">Data de Início do Plano</label>
          <input type="date" :class="inputClass" :value="modelValue.plan_start_date"
            @input="updateField('plan_start_date', $event.target.value)" />
        </div>
        <div>
          <label :class="labelClass">Data de Término do Plano</label>
          <input type="date" :class="inputClass" :value="modelValue.plan_end_date"
            @input="updateField('plan_end_date', $event.target.value)" />
        </div>
      </div>

      <div class="p-4 rounded-lg bg-n-alpha-2 border border-n-weak">
        <p class="text-sm font-medium text-n-slate-12 mb-3">Sessões Incluídas</p>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div>
            <label class="block text-xs text-n-slate-11 mb-1">Call Estratégica</label>
            <input type="number" min="0" :class="inputClass + ' text-center'" :value="modelValue.sessions_call_estrategica"
              @input="updateField('sessions_call_estrategica', parseInt($event.target.value) || 0)" />
          </div>
          <div>
            <label class="block text-xs text-n-slate-11 mb-1">Individuais</label>
            <input type="number" min="0" :class="inputClass + ' text-center'" :value="modelValue.sessions_individual"
              @input="updateField('sessions_individual', parseInt($event.target.value) || 0)" />
          </div>
          <div>
            <label class="block text-xs text-n-slate-11 mb-1">Consultivas Grupo</label>
            <input type="number" min="0" :class="inputClass + ' text-center'" :value="modelValue.sessions_group_consultive"
              @input="updateField('sessions_group_consultive', parseInt($event.target.value) || 0)" />
          </div>
          <div>
            <label class="block text-xs text-n-slate-11 mb-1">Encontros Grupo</label>
            <input type="number" min="0" :class="inputClass + ' text-center'" :value="modelValue.sessions_group_meetings"
              @input="updateField('sessions_group_meetings', parseInt($event.target.value) || 0)" />
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div>
          <label :class="labelClass">Valor Total *</label>
          <div class="relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-n-slate-10 z-10 pointer-events-none">R$</span>
            <input type="text" :class="inputClass" style="padding-left: 2.5rem;"
              :value="displayCurrency(modelValue.plan_value)"
              placeholder="0,00" @input="handleCurrencyInput('plan_value', $event)" />
          </div>
        </div>
        <div>
          <label :class="labelClass">Parcelas *</label>
          <input type="number" min="1" max="48" :class="inputClass" :value="modelValue.installments_count"
            @input="updateField('installments_count', parseInt($event.target.value) || 1)" />
        </div>
        <div>
          <label :class="labelClass">Dia Vencimento</label>
          <input type="number" min="1" max="31" :class="inputClass" :value="modelValue.installment_due_day"
            @input="updateField('installment_due_day', parseInt($event.target.value) || 10)" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label :class="labelClass">Valor 1ª Parcela (se diferente)</label>
          <div class="relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-n-slate-10 z-10 pointer-events-none">R$</span>
            <input type="text" :class="inputClass" style="padding-left: 2.5rem;"
              :value="displayCurrency(modelValue.first_installment_value)"
              placeholder="0,00" @input="handleCurrencyInput('first_installment_value', $event)" />
          </div>
          <p class="text-xs text-n-slate-11 mt-1">Deixe em branco se todas iguais</p>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.select-dark option {
  background-color: #1e1e2e;
  color: #e2e8f0;
}
</style>
