<script setup>
const props = defineProps({
  modelValue: { type: Object, required: true },
  section: { type: String, default: 'contractor' },
});

const emit = defineEmits(['update:modelValue']);

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
  if (!v) return '';
  const n = v.toString().replace(/\D/g, '');
  const amount = parseInt(n, 10) / 100;
  return amount.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

const parseCurrency = v => {
  if (!v) return '';
  const n = v.replace(/\D/g, '');
  return (parseInt(n, 10) / 100).toFixed(2);
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
          <select :class="inputClass" :value="modelValue.contractor_state"
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
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-n-slate-10">R$</span>
            <input type="text" :class="inputClass + ' pl-9'"
              :value="modelValue.plan_value ? formatCurrency(modelValue.plan_value * 100) : ''"
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
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-n-slate-10">R$</span>
            <input type="text" :class="inputClass + ' pl-9'"
              :value="modelValue.first_installment_value ? formatCurrency(modelValue.first_installment_value * 100) : ''"
              placeholder="0,00" @input="handleCurrencyInput('first_installment_value', $event)" />
          </div>
          <p class="text-xs text-n-slate-11 mt-1">Deixe em branco se todas iguais</p>
        </div>
      </div>
    </template>
  </div>
</template>
