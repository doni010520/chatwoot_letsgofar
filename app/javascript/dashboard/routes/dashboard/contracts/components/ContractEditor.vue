<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  title: { type: String, default: '' },
  readonly: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue', 'update:title']);

const isEditing = ref(false);
const editableContent = ref(props.modelValue);

const toggleEdit = () => {
  if (isEditing.value) {
    emit('update:modelValue', editableContent.value);
  } else {
    editableContent.value = props.modelValue;
  }
  isEditing.value = !isEditing.value;
};

const inputClass = 'w-full h-10 px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-brand';
</script>

<template>
  <div class="rounded-xl bg-n-solid-2 border border-n-weak overflow-hidden">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex-1 mr-4">
        <input
          v-if="!readonly"
          type="text"
          :class="inputClass"
          :value="title"
          placeholder="Título do contrato"
          @input="$emit('update:title', $event.target.value)"
        />
        <h3 v-else class="text-base font-medium text-n-slate-12">{{ title }}</h3>
      </div>
      <Button
        v-if="!readonly"
        :label="isEditing ? 'Salvar' : 'Editar HTML'"
        :icon="isEditing ? 'i-lucide-check' : 'i-lucide-pencil'"
        variant="faded"
        color="slate"
        size="sm"
        @click="toggleEdit"
      />
    </div>

    <!-- Content -->
    <div class="p-6">
      <textarea
        v-if="isEditing"
        v-model="editableContent"
        class="w-full min-h-[400px] px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak border-none text-n-slate-12 font-mono focus:outline-n-brand"
      />
      <div
        v-else-if="modelValue"
        class="prose prose-sm max-w-none text-n-slate-12"
        v-html="modelValue"
      />
      <p v-else class="text-sm text-n-slate-11 text-center py-8">
        Nenhum conteúdo disponível. Preencha os dados nos passos anteriores.
      </p>
    </div>
  </div>
</template>
