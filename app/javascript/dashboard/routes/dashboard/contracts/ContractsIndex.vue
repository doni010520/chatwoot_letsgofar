<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';

import ContractsAPI from 'dashboard/api/contracts';
import ContractCard from './components/ContractCard.vue';
import ContractFilters from './components/ContractFilters.vue';
import ContractStats from './components/ContractStats.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute } = useAccount();

// Estado
const contracts = ref([]);
const expiringContracts = ref([]);
const stats = ref(null);
const isLoading = ref(true);
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);

// Filtros
const filters = ref({
  status: null,
  q: '',
  sort_by: 'created_at',
  sort_order: 'desc',
});

// Status da rota
const routeStatus = computed(() => {
  const path = route.path;
  if (path.includes('/status/draft')) return 'draft';
  if (path.includes('/status/pending')) return 'pending';
  if (path.includes('/status/signed')) return 'signed';
  if (path.includes('/status/refused')) return 'refused';
  return null;
});

// Tabs de status
const statusTabs = computed(() => [
  { key: null, label: 'Todos', count: stats.value?.total || 0, route: 'contracts_list', icon: 'i-lucide-files' },
  { key: 'draft', label: 'Rascunhos', count: stats.value?.draft || 0, route: 'contracts_draft', icon: 'i-lucide-file-edit' },
  { key: 'pending', label: 'Aguardando', count: stats.value?.pending || 0, route: 'contracts_pending', icon: 'i-lucide-clock' },
  { key: 'signed', label: 'Assinados', count: stats.value?.signed || 0, route: 'contracts_signed', icon: 'i-lucide-check-circle' },
  { key: 'refused', label: 'Recusados', count: stats.value?.refused || 0, route: 'contracts_refused', icon: 'i-lucide-x-circle' },
]);

const activeTab = computed(() => routeStatus.value);

// Carregar contratos
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

// Carregar estatísticas
const loadStats = async () => {
  try {
    const response = await ContractsAPI.stats();
    stats.value = response.data;
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error);
  }
};

// Criar novo contrato
const createContract = () => {
  router.push(accountScopedRoute('contracts_create'));
};

// Visualizar contrato
const viewContract = (contract) => {
  router.push(accountScopedRoute('contracts_view', { contractId: contract.id }));
};

// Mudar tab de status
const changeTab = (tab) => {
  router.push(accountScopedRoute(tab.route));
};

// Aplicar filtros
const applyFilters = (newFilters) => {
  filters.value = { ...filters.value, ...newFilters };
  currentPage.value = 1;
  loadContracts();
};

// Mudar página
const changePage = (page) => {
  currentPage.value = page;
  loadContracts();
};

// Observar mudanças na rota
watch(() => route.path, () => {
  currentPage.value = 1;
  loadContracts();
});

// Carregar contratos vencendo
const loadExpiring = async () => {
  try {
    const response = await ContractsAPI.expiring();
    expiringContracts.value = response.data.data || [];
  } catch (error) {
    console.error('Erro ao carregar vencimentos:', error);
  }
};

const formatDate = dateStr => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('pt-BR');
};

const daysUntilExpiry = dateStr => {
  if (!dateStr) return null;
  const diff = (new Date(dateStr) - new Date()) / (1000 * 60 * 60 * 24);
  return Math.ceil(diff);
};

// Carregar dados ao montar
onMounted(() => {
  loadContracts();
  loadStats();
  loadExpiring();
});
</script>

<template>
  <div class="contracts-page flex flex-col h-full bg-slate-50 dark:bg-slate-900">
    <!-- Header com gradiente sutil -->
    <header class="relative px-8 py-6 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-rose-500 to-rose-700 flex items-center justify-center shadow-lg shadow-rose-500/20">
            <span class="i-lucide-file-signature text-white text-xl" />
          </div>
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">
              Contratos
            </h1>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
              Gerencie seus contratos de prestação de serviços
            </p>
          </div>
        </div>
        <button
          class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-700 hover:to-rose-800 text-white font-medium rounded-xl shadow-lg shadow-rose-500/25 hover:shadow-rose-500/40 transition-all duration-200 transform hover:scale-[1.02]"
          @click="createContract"
        >
          <span class="i-lucide-plus text-lg transition-transform group-hover:rotate-90 duration-200" />
          Novo Contrato
        </button>
      </div>
    </header>

    <!-- Stats Cards -->
    <ContractStats v-if="stats" :stats="stats" class="px-8 py-5" />

    <!-- Tabs de Status - Design moderno -->
    <nav class="px-8 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
      <div class="flex gap-1 -mb-px overflow-x-auto scrollbar-hide">
        <button
          v-for="tab in statusTabs"
          :key="tab.key"
          class="group flex items-center gap-2 px-4 py-3.5 text-sm font-medium transition-all duration-200 border-b-2 whitespace-nowrap"
          :class="[
            activeTab === tab.key
              ? 'border-rose-600 text-rose-600 dark:text-rose-500'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
          ]"
          @click="changeTab(tab)"
        >
          <span 
            :class="tab.icon" 
            class="text-base transition-transform group-hover:scale-110"
          />
          {{ tab.label }}
          <span
            class="px-2 py-0.5 text-xs font-semibold rounded-full transition-colors"
            :class="activeTab === tab.key 
              ? 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400' 
              : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300'"
          >
            {{ tab.count }}
          </span>
        </button>
      </div>
    </nav>

    <!-- Filtros -->
    <ContractFilters
      :filters="filters"
      class="px-8 py-4 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700"
      @update:filters="applyFilters"
    />

    <!-- Banner de Contratos Vencendo -->
    <div
      v-if="expiringContracts.length > 0"
      class="mx-8 mt-4 p-4 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 rounded-xl"
    >
      <div class="flex items-center gap-2 mb-3">
        <span class="i-lucide-alert-triangle text-amber-600 text-lg" />
        <h3 class="text-sm font-semibold text-amber-800 dark:text-amber-300">
          {{ expiringContracts.length }} contrato(s) vencendo nos pr&oacute;ximos 30 dias
        </h3>
      </div>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="ec in expiringContracts.slice(0, 5)"
          :key="ec.id"
          class="flex items-center gap-2 px-3 py-1.5 bg-white dark:bg-slate-800 border border-amber-200 dark:border-amber-700 rounded-lg text-xs hover:bg-amber-100 dark:hover:bg-amber-900/30 transition-colors"
          @click="viewContract(ec)"
        >
          <span class="font-medium text-slate-700 dark:text-slate-200">{{ ec.contractor_name || ec.title }}</span>
          <span class="text-amber-600 dark:text-amber-400">
            {{ daysUntilExpiry(ec.plan_end_date) }}d
          </span>
        </button>
        <span
          v-if="expiringContracts.length > 5"
          class="px-3 py-1.5 text-xs text-amber-600 dark:text-amber-400"
        >
          +{{ expiringContracts.length - 5 }} mais
        </span>
      </div>
    </div>

    <!-- Conteúdo Principal -->
    <div class="flex-1 overflow-auto px-8 py-6">
      <!-- Loading State -->
      <div v-if="isLoading" class="flex flex-col items-center justify-center h-64 gap-4">
        <div class="relative">
          <div class="w-12 h-12 rounded-full border-4 border-slate-200 dark:border-slate-700" />
          <div class="absolute inset-0 w-12 h-12 rounded-full border-4 border-rose-600 border-t-transparent animate-spin" />
        </div>
        <p class="text-sm text-slate-500 dark:text-slate-400">Carregando contratos...</p>
      </div>

      <!-- Empty State -->
      <div
        v-else-if="contracts.length === 0"
        class="flex flex-col items-center justify-center h-96 text-center"
      >
        <div class="w-24 h-24 rounded-2xl bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 flex items-center justify-center mb-6">
          <span class="i-lucide-file-x text-4xl text-slate-400 dark:text-slate-500" />
        </div>
        <h3 class="text-xl font-semibold text-slate-900 dark:text-white mb-2">
          Nenhum contrato encontrado
        </h3>
        <p class="text-slate-500 dark:text-slate-400 mb-6 max-w-sm">
          Comece criando seu primeiro contrato de prestação de serviços
        </p>
        <button
          class="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-700 hover:to-rose-800 text-white font-medium rounded-xl shadow-lg shadow-rose-500/25 transition-all duration-200"
          @click="createContract"
        >
          <span class="i-lucide-plus" />
          Criar Primeiro Contrato
        </button>
      </div>

      <!-- Lista de Contratos -->
      <div v-else class="space-y-3">
        <TransitionGroup name="list">
          <ContractCard
            v-for="contract in contracts"
            :key="contract.id"
            :contract="contract"
            @click="viewContract(contract)"
          />
        </TransitionGroup>
      </div>

      <!-- Paginação -->
      <div v-if="totalPages > 1" class="flex items-center justify-center gap-2 mt-8">
        <button
          class="p-2 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          :disabled="currentPage === 1"
          @click="changePage(currentPage - 1)"
        >
          <span class="i-lucide-chevron-left text-lg" />
        </button>
        
        <div class="flex gap-1">
          <button
            v-for="page in totalPages"
            :key="page"
            class="min-w-[40px] h-10 px-3 text-sm font-medium rounded-lg transition-all duration-200"
            :class="[
              currentPage === page
                ? 'bg-rose-600 text-white shadow-lg shadow-rose-500/25'
                : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800'
            ]"
            @click="changePage(page)"
          >
            {{ page }}
          </button>
        </div>
        
        <button
          class="p-2 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          :disabled="currentPage === totalPages"
          @click="changePage(currentPage + 1)"
        >
          <span class="i-lucide-chevron-right text-lg" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.list-enter-active,
.list-leave-active {
  transition: all 0.3s ease;
}
.list-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}
.list-leave-to {
  opacity: 0;
  transform: translateX(-10px);
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
