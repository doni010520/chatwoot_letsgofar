<script setup>
import { computed } from 'vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
  section: {
    type: String,
    default: 'contractor', // 'contractor' ou 'plan'
  },
});

const emit = defineEmits(['update:modelValue']);

// Estados brasileiros
const states = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
  'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

// Atualizar campo
const updateField = (field, value) => {
  emit('update:modelValue', {
    ...props.modelValue,
    [field]: value,
  });
};

// Formatar CPF
const formatCPF = (value) => {
  if (!value) return '';
  const numbers = value.replace(/\D/g, '').slice(0, 11);
  if (numbers.length <= 3) return numbers;
  if (numbers.length <= 6) return `${numbers.slice(0, 3)}.${numbers.slice(3)}`;
  if (numbers.length <= 9) return `${numbers.slice(0, 3)}.${numbers.slice(3, 6)}.${numbers.slice(6)}`;
  return `${numbers.slice(0, 3)}.${numbers.slice(3, 6)}.${numbers.slice(6, 9)}-${numbers.slice(9)}`;
};

// Formatar telefone
const formatPhone = (value) => {
  if (!value) return '';
  const numbers = value.replace(/\D/g, '').slice(0, 11);
  if (numbers.length <= 2) return `(${numbers}`;
  if (numbers.length <= 7) return `(${numbers.slice(0, 2)}) ${numbers.slice(2)}`;
  return `(${numbers.slice(0, 2)}) ${numbers.slice(2, 7)}-${numbers.slice(7)}`;
};

// Formatar CEP
const formatCEP = (value) => {
  if (!value) return '';
  const numbers = value.replace(/\D/g, '').slice(0, 8);
  if (numbers.length <= 5) return numbers;
  return `${numbers.slice(0, 5)}-${numbers.slice(5)}`;
};

// Formatar moeda
const formatCurrency = (value) => {
  if (!value) return '';
  const numbers = value.toString().replace(/\D/g, '');
  const amount = parseInt(numbers, 10) / 100;
  return amount.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

// Parse moeda para número
const parseCurrency = (value) => {
  if (!value) return '';
  const numbers = value.replace(/\D/g, '');
  return (parseInt(numbers, 10) / 100).toFixed(2);
};

// Handlers de input com formatação
const handleCPFInput = (e) => {
  const formatted = formatCPF(e.target.value);
  e.target.value = formatted;
  updateField('contractor_cpf', formatted);
};

const handlePhoneInput = (e) => {
  const formatted = formatPhone(e.target.value);
  e.target.value = formatted;
  updateField('contractor_phone', formatted);
};

const handleCEPInput = (e) => {
  const formatted = formatCEP(e.target.value);
  e.target.value = formatted;
  updateField('contractor_cep', formatted);
};

const handleCurrencyInput = (field, e) => {
  const formatted = formatCurrency(e.target.value);
  e.target.value = formatted;
  updateField(field, parseCurrency(e.target.value));
};
</script>

<template>
  <div class="space-y-6">
    <!-- Seção: Dados do Contratante -->
    <template v-if="section === 'contractor'">
      <!-- Nome e CPF -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Nome Completo *
          </label>
          <input
            type="text"
            :value="modelValue.contractor_name"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Nome completo do contratante"
            @input="updateField('contractor_name', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            CPF *
          </label>
          <input
            type="text"
            :value="modelValue.contractor_cpf"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="000.000.000-00"
            @input="handleCPFInput"
          />
        </div>
      </div>

      <!-- RG e Data de Nascimento -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            RG
          </label>
          <input
            type="text"
            :value="modelValue.contractor_rg"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Número do RG"
            @input="updateField('contractor_rg', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Data de Nascimento
          </label>
          <input
            type="date"
            :value="modelValue.contractor_birth_date"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            @input="updateField('contractor_birth_date', $event.target.value)"
          />
        </div>
      </div>

      <!-- E-mail e Telefone -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            E-mail *
          </label>
          <input
            type="email"
            :value="modelValue.contractor_email"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="email@exemplo.com"
            @input="updateField('contractor_email', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Telefone *
          </label>
          <input
            type="text"
            :value="modelValue.contractor_phone"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="(00) 00000-0000"
            @input="handlePhoneInput"
          />
        </div>
      </div>

      <!-- Endereço -->
      <div>
        <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
          Endereço *
        </label>
        <input
          type="text"
          :value="modelValue.contractor_address"
          class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
          placeholder="Rua, número, complemento"
          @input="updateField('contractor_address', $event.target.value)"
        />
      </div>

      <!-- Bairro, Cidade, Estado, CEP -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Bairro
          </label>
          <input
            type="text"
            :value="modelValue.contractor_neighborhood"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Bairro"
            @input="updateField('contractor_neighborhood', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Cidade *
          </label>
          <input
            type="text"
            :value="modelValue.contractor_city"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Cidade"
            @input="updateField('contractor_city', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Estado *
          </label>
          <select
            :value="modelValue.contractor_state"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            @change="updateField('contractor_state', $event.target.value)"
          >
            <option value="">UF</option>
            <option v-for="state in states" :key="state" :value="state">
              {{ state }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            CEP
          </label>
          <input
            type="text"
            :value="modelValue.contractor_cep"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="00000-000"
            @input="handleCEPInput"
          />
        </div>
      </div>
    </template>

    <!-- Seção: Dados do Plano -->
    <template v-if="section === 'plan'">
      <!-- Nome do Plano e Duração -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Nome do Plano *
          </label>
          <input
            type="text"
            :value="modelValue.plan_name"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Ex: Plano Premium Anual"
            @input="updateField('plan_name', $event.target.value)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Duração *
          </label>
          <input
            type="text"
            :value="modelValue.plan_duration"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Ex: 12 meses"
            @input="updateField('plan_duration', $event.target.value)"
          />
        </div>
      </div>

      <!-- Sessões -->
      <div class="p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700">
        <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-4">
          Sessões Incluídas
        </h4>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
              Call Estratégica
            </label>
            <input
              type="number"
              min="0"
              :value="modelValue.sessions_call_estrategica"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-center focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              @input="updateField('sessions_call_estrategica', parseInt($event.target.value) || 0)"
            />
          </div>
          <div>
            <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
              Sessões Individuais
            </label>
            <input
              type="number"
              min="0"
              :value="modelValue.sessions_individual"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-center focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              @input="updateField('sessions_individual', parseInt($event.target.value) || 0)"
            />
          </div>
          <div>
            <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
              Consultivas em Grupo
            </label>
            <input
              type="number"
              min="0"
              :value="modelValue.sessions_group_consultive"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-center focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              @input="updateField('sessions_group_consultive', parseInt($event.target.value) || 0)"
            />
          </div>
          <div>
            <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
              Encontros em Grupo
            </label>
            <input
              type="number"
              min="0"
              :value="modelValue.sessions_group_meetings"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-center focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              @input="updateField('sessions_group_meetings', parseInt($event.target.value) || 0)"
            />
          </div>
        </div>
      </div>

      <!-- Valores -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Valor Total *
          </label>
          <div class="relative">
            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">R$</span>
            <input
              type="text"
              :value="modelValue.plan_value ? formatCurrency(modelValue.plan_value * 100) : ''"
              class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              placeholder="0,00"
              @input="handleCurrencyInput('plan_value', $event)"
            />
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Número de Parcelas *
          </label>
          <input
            type="number"
            min="1"
            max="48"
            :value="modelValue.installments_count"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="12"
            @input="updateField('installments_count', parseInt($event.target.value) || 1)"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Dia de Vencimento *
          </label>
          <input
            type="number"
            min="1"
            max="31"
            :value="modelValue.installment_due_day"
            class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="10"
            @input="updateField('installment_due_day', parseInt($event.target.value) || 10)"
          />
        </div>
      </div>

      <!-- Valor da primeira parcela (opcional) -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
            Valor da 1ª Parcela (se diferente)
          </label>
          <div class="relative">
            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">R$</span>
            <input
              type="text"
              :value="modelValue.first_installment_value ? formatCurrency(modelValue.first_installment_value * 100) : ''"
              class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
              placeholder="0,00"
              @input="handleCurrencyInput('first_installment_value', $event)"
            />
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Deixe em branco se todas as parcelas tiverem o mesmo valor
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
