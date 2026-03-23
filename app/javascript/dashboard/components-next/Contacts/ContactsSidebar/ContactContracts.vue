<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContractsAPI from 'dashboard/api/contracts';

const props = defineProps({
  contactId: {
    type: [String, Number],
    required: true,
  },
});

const route = useRoute();
const router = useRouter();

const contracts = ref([]);
const isLoading = ref(true);

const accountId = computed(() => route.params.accountId);

const statusBadge = status => {
  const map = {
    draft: { label: 'Rascunho', class: 'bg-n-slate-3 text-n-slate-11' },
    pending: {
      label: 'Pendente',
      class: 'bg-y-yellow-3 text-y-yellow-11',
    },
    partially_signed: {
      label: 'Parcial',
      class: 'bg-b-blue-3 text-b-blue-11',
    },
    signed: { label: 'Assinado', class: 'bg-g-green-3 text-g-green-11' },
    refused: { label: 'Recusado', class: 'bg-r-red-3 text-r-red-11' },
    expired: { label: 'Expirado', class: 'bg-n-slate-3 text-n-slate-11' },
    cancelled: {
      label: 'Cancelado',
      class: 'bg-n-slate-3 text-n-slate-11',
    },
  };
  return map[status] || { label: status, class: 'bg-n-slate-3 text-n-slate-11' };
};

const formatDate = dateStr => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('pt-BR');
};

const isExpiringSoon = contract => {
  if (!contract.plan_end_date) return false;
  const endDate = new Date(contract.plan_end_date);
  const now = new Date();
  const diffDays = (endDate - now) / (1000 * 60 * 60 * 24);
  return diffDays >= 0 && diffDays <= 30;
};

const goToContract = contractId => {
  router.push(
    `/app/accounts/${accountId.value}/contracts/${contractId}`
  );
};

const goToCreateContract = () => {
  router.push(
    `/app/accounts/${accountId.value}/contracts/create?contact_id=${props.contactId}`
  );
};

const fetchContracts = async () => {
  isLoading.value = true;
  try {
    const response = await ContractsAPI.list({
      contact_id: props.contactId,
    });
    contracts.value = response.data.data || [];
  } catch (error) {
    contracts.value = [];
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchContracts);
</script>

<template>
  <div class="flex flex-col gap-4 py-6 px-6">
    <div class="flex items-center justify-between">
      <h3 class="text-sm font-semibold text-n-slate-12">Contratos</h3>
      <Button
        variant="link"
        color="blue"
        size="sm"
        label="Novo Contrato"
        class="hover:no-underline"
        @click="goToCreateContract"
      />
    </div>

    <div
      v-if="isLoading"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div v-else-if="contracts.length > 0" class="flex flex-col gap-3">
      <div
        v-for="contract in contracts"
        :key="contract.id"
        class="p-3 border rounded-lg cursor-pointer hover:bg-n-alpha-black2 transition-colors"
        :class="{ 'border-y-yellow-6 bg-y-yellow-2': isExpiringSoon(contract) }"
        @click="goToContract(contract.id)"
      >
        <div class="flex items-start justify-between gap-2">
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ contract.title }}
            </p>
            <p class="text-xs text-n-slate-11 mt-0.5">
              {{ contract.contract_number }}
            </p>
          </div>
          <span
            class="px-2 py-0.5 text-xs font-medium rounded-full whitespace-nowrap"
            :class="statusBadge(contract.status).class"
          >
            {{ statusBadge(contract.status).label }}
          </span>
        </div>

        <div class="flex items-center gap-4 mt-2 text-xs text-n-slate-10">
          <span v-if="contract.plan_name">{{ contract.plan_name }}</span>
          <span v-if="contract.plan_end_date">
            Vence: {{ formatDate(contract.plan_end_date) }}
          </span>
          <span
            v-if="isExpiringSoon(contract)"
            class="text-y-yellow-11 font-medium"
          >
            Vencendo!
          </span>
        </div>
      </div>
    </div>

    <p
      v-else
      class="py-6 text-sm leading-6 text-center text-n-slate-11"
    >
      Nenhum contrato vinculado a este contato.
    </p>
  </div>
</template>
