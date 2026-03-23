<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import ContractsAPI from 'dashboard/api/contracts';
import ContractCard from './components/ContractCard.vue';
import ContractFilters from './components/ContractFilters.vue';
import ContractStats from './components/ContractStats.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute } = useAccount();

const contracts = ref([]);
const expiringContracts = ref([]);
const stats = ref(null);
const isLoading = ref(true);
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);

const filters = ref({
  status: null,
  q: '',
  sort_by: 'created_at',
  sort_order: 'desc',
});

const routeStatus = computed(() => {
  const path = route.path;
  if (path.includes('/status/draft')) return 'draft';
  if (path.includes('/status/pending')) return 'pending';
  if (path.includes('/status/signed')) return 'signed';
  if (path.includes('/status/refused')) return 'refused';
  return null;
});

const statusTabs = [
  { key: null, label: 'Todos', route: 'contracts_list' },
  { key: 'draft', label: 'Rascunhos', route: 'contracts_draft' },
  { key: 'pending', label: 'Aguardando', route: 'contracts_pending' },
  { key: 'signed', label: 'Assinados', route: 'contracts_signed' },
  { key: 'refused', label: 'Recusados', route: 'contracts_refused' },
];

const activeTab = computed(() => routeStatus.value);

const loadContracts = async () => {
  isLoading.value = true;
  try {
    const params = {
      ...filters.value,
      status: routeStatus.value || filters.value.status,
      page: currentPage.value,
      per_page: 20,
    };
    const response = await ContractsAPI.list(params);
    contracts.value = response.data.data;
    totalPages.value = response.data.meta.total_pages;
    totalCount.value = response.data.meta.total_count;
  } catch (error) {
    console.error('Erro ao carregar contratos:', error);
  } finally {
    isLoading.value = false;
  }
};

const loadStats = async () => {
  try {
    const response = await ContractsAPI.stats();
    stats.value = response.data;
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error);
  }
};

const loadExpiring = async () => {
  try {
    const response = await ContractsAPI.expiring();
    expiringContracts.value = response.data.data || [];
  } catch (error) {
    console.error('Erro ao carregar vencimentos:', error);
  }
};

const createContract = () => {
  router.push(accountScopedRoute('contracts_create'));
};

const viewContract = contract => {
  router.push(
    accountScopedRoute('contracts_view', { contractId: contract.id })
  );
};

const changeTab = tab => {
  router.push(accountScopedRoute(tab.route));
};

const applyFilters = newFilters => {
  filters.value = { ...filters.value, ...newFilters };
  currentPage.value = 1;
  loadContracts();
};

const changePage = page => {
  currentPage.value = page;
  loadContracts();
};

const daysUntilExpiry = dateStr => {
  if (!dateStr) return null;
  const diff = (new Date(dateStr) - new Date()) / (1000 * 60 * 60 * 24);
  return Math.ceil(diff);
};

const tabCount = key => {
  if (!stats.value) return 0;
  if (key === null) return stats.value.total || 0;
  return stats.value[key] || 0;
};

watch(() => route.path, () => {
  currentPage.value = 1;
  loadContracts();
});

onMounted(() => {
  loadContracts();
  loadStats();
  loadExpiring();
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-surface-1">
    <!-- Header -->
    <header class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div>
        <h1 class="text-lg font-medium text-n-slate-12">Contratos</h1>
        <p class="text-sm text-n-slate-11">
          Gerencie seus contratos de prestação de serviços
        </p>
      </div>
      <Button
        label="Novo Contrato"
        icon="i-lucide-plus"
        color="blue"
        size="sm"
        @click="createContract"
      />
    </header>

    <!-- Stats -->
    <ContractStats v-if="stats" :stats="stats" class="px-6 py-4" />

    <!-- Expiring Contracts Banner -->
    <div
      v-if="expiringContracts.length > 0"
      class="mx-6 mb-2 p-3 rounded-lg bg-n-amber-3 border border-n-amber-6"
    >
      <div class="flex items-center gap-2 mb-2">
        <span class="i-lucide-alert-triangle text-n-amber-11" />
        <span class="text-sm font-medium text-n-amber-11">
          {{ expiringContracts.length }} contrato(s) vencendo nos próximos 30 dias
        </span>
      </div>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="ec in expiringContracts.slice(0, 5)"
          :key="ec.id"
          class="px-2.5 py-1 text-xs rounded-md bg-n-solid-2 border border-n-weak text-n-slate-12 hover:bg-n-alpha-3 transition-colors"
          @click="viewContract(ec)"
        >
          {{ ec.contractor_name || ec.title }}
          <span class="text-n-amber-11 ml-1">{{ daysUntilExpiry(ec.plan_end_date) }}d</span>
        </button>
        <span
          v-if="expiringContracts.length > 5"
          class="px-2.5 py-1 text-xs text-n-slate-11"
        >
          +{{ expiringContracts.length - 5 }} mais
        </span>
      </div>
    </div>

    <!-- Status Tabs -->
    <nav class="flex gap-1 px-6 border-b border-n-weak">
      <button
        v-for="tab in statusTabs"
        :key="tab.key"
        class="px-3 py-2.5 text-sm font-medium border-b-2 transition-colors"
        :class="[
          activeTab === tab.key
            ? 'border-n-brand text-n-brand'
            : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
        ]"
        @click="changeTab(tab)"
      >
        {{ tab.label }}
        <span
          class="ml-1 px-1.5 py-0.5 text-xs rounded-full"
          :class="activeTab === tab.key ? 'bg-n-brand text-white' : 'bg-n-alpha-3 text-n-slate-11'"
        >
          {{ tabCount(tab.key) }}
        </span>
      </button>
    </nav>

    <!-- Filters -->
    <ContractFilters
      :filters="filters"
      class="px-6 py-3 border-b border-n-weak"
      @update:filters="applyFilters"
    />

    <!-- Content -->
    <div class="flex-1 overflow-auto px-6 py-4">
      <!-- Loading -->
      <div v-if="isLoading" class="flex items-center justify-center py-16">
        <Spinner />
      </div>

      <!-- Empty State -->
      <div
        v-else-if="contracts.length === 0"
        class="flex flex-col items-center justify-center py-20 text-center"
      >
        <div class="w-16 h-16 rounded-xl bg-n-alpha-3 flex items-center justify-center mb-4">
          <span class="i-lucide-file-x text-2xl text-n-slate-10" />
        </div>
        <h3 class="text-base font-medium text-n-slate-12 mb-1">
          Nenhum contrato encontrado
        </h3>
        <p class="text-sm text-n-slate-11 mb-4 max-w-xs">
          Comece criando seu primeiro contrato de prestação de serviços
        </p>
        <Button
          label="Criar Primeiro Contrato"
          icon="i-lucide-plus"
          color="blue"
          size="sm"
          @click="createContract"
        />
      </div>

      <!-- Contract List -->
      <div v-else class="flex flex-col gap-2">
        <ContractCard
          v-for="contract in contracts"
          :key="contract.id"
          :contract="contract"
          @click="viewContract(contract)"
        />
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-center gap-1 mt-6 pb-4">
        <button
          class="p-2 rounded-lg text-n-slate-11 hover:bg-n-alpha-3 disabled:opacity-50"
          :disabled="currentPage === 1"
          @click="changePage(currentPage - 1)"
        >
          <span class="i-lucide-chevron-left" />
        </button>
        <button
          v-for="page in totalPages"
          :key="page"
          class="min-w-[32px] h-8 px-2 text-sm rounded-lg transition-colors"
          :class="[
            currentPage === page
              ? 'bg-n-brand text-white'
              : 'text-n-slate-11 hover:bg-n-alpha-3'
          ]"
          @click="changePage(page)"
        >
          {{ page }}
        </button>
        <button
          class="p-2 rounded-lg text-n-slate-11 hover:bg-n-alpha-3 disabled:opacity-50"
          :disabled="currentPage === totalPages"
          @click="changePage(currentPage + 1)"
        >
          <span class="i-lucide-chevron-right" />
        </button>
      </div>
    </div>
  </div>
</template>
