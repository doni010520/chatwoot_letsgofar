<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  signers: { type: Array, default: () => [] },
  contractorName: { type: String, default: '' },
  contractorEmail: { type: String, default: '' },
});

const emit = defineEmits(['update:signers']);

const newSigner = ref({ name: '', email: '', role: 'contractor' });

const addSigner = () => {
  if (!newSigner.value.name || !newSigner.value.email) return;
  const updated = [...props.signers, { ...newSigner.value }];
  emit('update:signers', updated);
  newSigner.value = { name: '', email: '', role: 'contractor' };
};

const removeSigner = index => {
  const updated = props.signers.filter((_, i) => i !== index);
  emit('update:signers', updated);
};

const addContractorAsSigner = () => {
  if (!props.contractorName || !props.contractorEmail) return;
  const updated = [...props.signers, {
    name: props.contractorName,
    email: props.contractorEmail,
    role: 'contractor',
  }];
  emit('update:signers', updated);
};

const roleLabel = role => {
  const map = { contractor: 'Contratante', contracted: 'Contratada', witness: 'Testemunha' };
  return map[role] || role;
};

const inputClass = 'w-full h-10 px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand';
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- Info -->
    <div class="p-3 rounded-lg bg-n-blue-3 border border-n-blue-6">
      <p class="text-sm text-n-blue-11">
        A empresa (Ianka Cavalcante) será adicionada automaticamente como signatária.
        Adicione aqui os demais signatários.
      </p>
    </div>

    <!-- Quick add contractor -->
    <div v-if="contractorName && contractorEmail && signers.length === 0">
      <Button
        :label="`Adicionar ${contractorName} como signatário`"
        icon="i-lucide-user-plus"
        variant="faded"
        color="blue"
        size="sm"
        @click="addContractorAsSigner"
      />
    </div>

    <!-- Signers list -->
    <div v-if="signers.length > 0" class="flex flex-col gap-2">
      <div
        v-for="(signer, index) in signers"
        :key="index"
        class="flex items-center justify-between p-3 rounded-lg bg-n-alpha-2 border border-n-weak"
      >
        <div>
          <p class="text-sm font-medium text-n-slate-12">{{ signer.name }}</p>
          <p class="text-xs text-n-slate-11">{{ signer.email }} - {{ roleLabel(signer.role) }}</p>
        </div>
        <button
          class="p-1 rounded text-n-slate-10 hover:text-n-ruby-9 hover:bg-n-ruby-3 transition-colors"
          @click="removeSigner(index)"
        >
          <span class="i-lucide-trash-2 text-sm" />
        </button>
      </div>
    </div>

    <!-- Add signer form -->
    <div class="p-4 rounded-lg border border-n-weak border-dashed">
      <p class="text-sm font-medium text-n-slate-12 mb-3">Adicionar Signatário</p>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <input v-model="newSigner.name" type="text" :class="inputClass" placeholder="Nome" />
        <input v-model="newSigner.email" type="email" :class="inputClass" placeholder="E-mail" />
        <select v-model="newSigner.role" :class="inputClass" class="select-dark">
          <option value="contractor">Contratante</option>
          <option value="contracted">Contratada</option>
          <option value="witness">Testemunha</option>
        </select>
      </div>
      <div class="mt-3">
        <Button
          label="Adicionar"
          icon="i-lucide-plus"
          variant="faded"
          color="blue"
          size="sm"
          :disabled="!newSigner.name || !newSigner.email"
          @click="addSigner"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.select-dark option {
  background-color: #1e1e2e;
  color: #e2e8f0;
}
</style>
