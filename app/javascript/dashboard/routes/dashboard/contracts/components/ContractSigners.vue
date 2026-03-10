<script setup>
import { ref, computed, watch, onMounted } from 'vue';

const props = defineProps({
  signers: {
    type: Array,
    default: () => [],
  },
  contractorName: {
    type: String,
    default: '',
  },
  contractorEmail: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:signers']);

// Lista local de signatários
const localSigners = ref([]);

// Sincronizar com props
watch(
  () => props.signers,
  (newVal) => {
    localSigners.value = [...newVal];
  },
  { immediate: true }
);

// Novo signatário
const newSigner = ref({
  name: '',
  email: '',
  role: 'contractor',
});

// Roles disponíveis
const roles = [
  { value: 'contractor', label: 'Contratante', icon: 'i-lucide-user' },
  { value: 'contracted', label: 'Contratada', icon: 'i-lucide-building-2' },
  { value: 'witness', label: 'Testemunha', icon: 'i-lucide-users' },
];

// Obter label do role
const getRoleLabel = (role) => {
  return roles.find((r) => r.value === role)?.label || role;
};

// Obter ícone do role
const getRoleIcon = (role) => {
  return roles.find((r) => r.value === role)?.icon || 'i-lucide-user';
};

// Adicionar signatário
const addSigner = () => {
  if (!newSigner.value.name || !newSigner.value.email) return;

  localSigners.value.push({
    ...newSigner.value,
    _key: Date.now(), // chave temporária para v-for
  });

  emit('update:signers', localSigners.value);

  // Limpar formulário
  newSigner.value = {
    name: '',
    email: '',
    role: 'witness',
  };
};

// Remover signatário
const removeSigner = (index) => {
  const signer = localSigners.value[index];
  
  if (signer.id) {
    // Marcar para remoção (para o backend)
    localSigners.value[index] = { ...signer, _destroy: true };
  } else {
    // Remover diretamente se ainda não foi salvo
    localSigners.value.splice(index, 1);
  }

  emit('update:signers', localSigners.value.filter((s) => !s._destroy));
};

// Adicionar contratante automaticamente
const addContractorAsSigner = () => {
  if (!props.contractorName || !props.contractorEmail) return;

  // Verificar se já existe
  const exists = localSigners.value.some(
    (s) => s.email === props.contractorEmail && !s._destroy
  );

  if (exists) return;

  localSigners.value.push({
    name: props.contractorName,
    email: props.contractorEmail,
    role: 'contractor',
    _key: Date.now(),
  });

  emit('update:signers', localSigners.value);
};

// Signatários visíveis (sem os marcados para remoção)
const visibleSigners = computed(() => {
  return localSigners.value.filter((s) => !s._destroy);
});

// Verificar se contratante já foi adicionado
const contractorAdded = computed(() => {
  return localSigners.value.some(
    (s) => s.email === props.contractorEmail && !s._destroy
  );
});

// Ao montar, adicionar contratante se houver dados
onMounted(() => {
  if (props.contractorName && props.contractorEmail && localSigners.value.length === 0) {
    addContractorAsSigner();
  }
});
</script>

<template>
  <div class="space-y-6">
    <!-- Dica -->
    <div class="p-4 rounded-xl bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
      <div class="flex gap-3">
        <span class="i-lucide-info text-amber-600 dark:text-amber-500 text-lg flex-shrink-0 mt-0.5" />
        <div class="text-sm text-amber-800 dark:text-amber-200">
          <p class="font-medium mb-1">Como funciona a assinatura?</p>
          <p class="text-amber-700 dark:text-amber-300">
            Cada signatário receberá um link único por e-mail para assinar o contrato. 
            A assinatura é eletrônica e possui validade jurídica conforme a Lei nº 14.620/2023.
          </p>
        </div>
      </div>
    </div>

    <!-- Adicionar contratante rapidamente -->
    <div
      v-if="contractorName && contractorEmail && !contractorAdded"
      class="p-4 rounded-xl bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800"
    >
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-rose-100 dark:bg-rose-800 flex items-center justify-center">
            <span class="i-lucide-user-plus text-rose-600 dark:text-rose-400" />
          </div>
          <div>
            <p class="font-medium text-slate-900 dark:text-white">{{ contractorName }}</p>
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ contractorEmail }}</p>
          </div>
        </div>
        <button
          type="button"
          class="px-4 py-2 text-sm font-medium text-rose-600 dark:text-rose-400 bg-white dark:bg-slate-800 rounded-lg border border-rose-200 dark:border-rose-700 hover:bg-rose-50 dark:hover:bg-rose-900/30 transition-colors"
          @click="addContractorAsSigner"
        >
          Adicionar como Contratante
        </button>
      </div>
    </div>

    <!-- Lista de signatários -->
    <div v-if="visibleSigners.length > 0" class="space-y-3">
      <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300">
        Signatários ({{ visibleSigners.length }})
      </h4>

      <TransitionGroup name="list" tag="div" class="space-y-2">
        <div
          v-for="(signer, index) in visibleSigners"
          :key="signer._key || signer.id || index"
          class="group flex items-center gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 hover:border-rose-200 dark:hover:border-rose-800 transition-colors"
        >
          <!-- Ícone do role -->
          <div
            class="w-10 h-10 rounded-full flex items-center justify-center"
            :class="[
              signer.role === 'contractor'
                ? 'bg-blue-100 dark:bg-blue-900/30'
                : signer.role === 'contracted'
                  ? 'bg-green-100 dark:bg-green-900/30'
                  : 'bg-slate-100 dark:bg-slate-800'
            ]"
          >
            <span
              :class="[
                getRoleIcon(signer.role),
                signer.role === 'contractor'
                  ? 'text-blue-600 dark:text-blue-400'
                  : signer.role === 'contracted'
                    ? 'text-green-600 dark:text-green-400'
                    : 'text-slate-500 dark:text-slate-400'
              ]"
            />
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <p class="font-medium text-slate-900 dark:text-white truncate">
              {{ signer.name }}
            </p>
            <p class="text-sm text-slate-500 dark:text-slate-400 truncate">
              {{ signer.email }}
            </p>
          </div>

          <!-- Role badge -->
          <span
            class="px-2.5 py-1 text-xs font-medium rounded-full"
            :class="[
              signer.role === 'contractor'
                ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                : signer.role === 'contracted'
                  ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                  : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
            ]"
          >
            {{ getRoleLabel(signer.role) }}
          </span>

          <!-- Botão remover -->
          <button
            type="button"
            class="p-2 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 opacity-0 group-hover:opacity-100 transition-all"
            @click="removeSigner(index)"
          >
            <span class="i-lucide-trash-2" />
          </button>
        </div>
      </TransitionGroup>
    </div>

    <!-- Formulário para adicionar -->
    <div class="p-5 rounded-xl border-2 border-dashed border-slate-200 dark:border-slate-700 hover:border-rose-300 dark:hover:border-rose-700 transition-colors">
      <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-4 flex items-center gap-2">
        <span class="i-lucide-user-plus text-rose-600" />
        Adicionar Signatário
      </h4>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="md:col-span-1">
          <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
            Papel
          </label>
          <select
            v-model="newSigner.role"
            class="w-full px-3 py-2.5 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
          >
            <option v-for="role in roles" :key="role.value" :value="role.value">
              {{ role.label }}
            </option>
          </select>
        </div>

        <div class="md:col-span-1">
          <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
            Nome *
          </label>
          <input
            v-model="newSigner.name"
            type="text"
            class="w-full px-3 py-2.5 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="Nome completo"
          />
        </div>

        <div class="md:col-span-1">
          <label class="block text-xs text-slate-500 dark:text-slate-400 mb-1">
            E-mail *
          </label>
          <input
            v-model="newSigner.email"
            type="email"
            class="w-full px-3 py-2.5 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-rose-500 focus:border-transparent transition-shadow"
            placeholder="email@exemplo.com"
          />
        </div>

        <div class="md:col-span-1 flex items-end">
          <button
            type="button"
            class="w-full px-4 py-2.5 bg-rose-600 hover:bg-rose-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!newSigner.name || !newSigner.email"
            @click="addSigner"
          >
            <span class="i-lucide-plus mr-1" />
            Adicionar
          </button>
        </div>
      </div>
    </div>

    <!-- Aviso se não houver signatários -->
    <div
      v-if="visibleSigners.length === 0"
      class="p-6 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-center"
    >
      <span class="i-lucide-users text-3xl text-slate-300 dark:text-slate-600 mb-3" />
      <p class="text-slate-500 dark:text-slate-400">
        Adicione pelo menos um signatário para continuar
      </p>
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
  transform: translateX(-20px);
}
.list-leave-to {
  opacity: 0;
  transform: translateX(20px);
}
</style>
