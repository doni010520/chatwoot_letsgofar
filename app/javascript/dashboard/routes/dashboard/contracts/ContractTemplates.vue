<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import { ContractTemplates } from 'dashboard/api/contracts';
import Button from 'dashboard/components-next/button/Button.vue';

const templates = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const showDeleteConfirm = ref(false);
const editingTemplate = ref(null);
const deletingTemplate = ref(null);
const isSaving = ref(false);

const formData = ref({
  name: '',
  description: '',
  content_html: '',
  active: true,
});

const modalTitle = computed(() =>
  editingTemplate.value ? 'Editar Modelo' : 'Novo Modelo de Contrato'
);

const formatDate = dateStr => {
  if (!dateStr) return '-';
  const date = new Date(dateStr);
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const fetchTemplates = async () => {
  isLoading.value = true;
  try {
    const response = await ContractTemplates.list();
    templates.value = response.data.data || response.data || [];
  } catch (error) {
    useAlert('Erro ao carregar modelos de contrato.');
    console.error('Erro ao carregar templates:', error);
  } finally {
    isLoading.value = false;
  }
};

const openCreateModal = () => {
  editingTemplate.value = null;
  formData.value = {
    name: '',
    description: '',
    content_html: '',
    active: true,
  };
  showModal.value = true;
};

const openEditModal = template => {
  editingTemplate.value = template;
  formData.value = {
    name: template.name,
    description: template.description || '',
    content_html: template.content_html || '',
    active: template.active ?? true,
  };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  editingTemplate.value = null;
};

const saveTemplate = async () => {
  if (!formData.value.name.trim()) {
    useAlert('O nome do modelo é obrigatório.');
    return;
  }

  isSaving.value = true;
  try {
    if (editingTemplate.value) {
      await ContractTemplates.update(editingTemplate.value.id, formData.value);
      useAlert('Modelo atualizado com sucesso.');
    } else {
      await ContractTemplates.create(formData.value);
      useAlert('Modelo criado com sucesso.');
    }
    closeModal();
    await fetchTemplates();
  } catch (error) {
    useAlert('Erro ao salvar modelo.');
    console.error('Erro ao salvar template:', error);
  } finally {
    isSaving.value = false;
  }
};

const duplicateTemplate = async template => {
  try {
    await ContractTemplates.create({
      name: `${template.name} (Cópia)`,
      description: template.description || '',
      content_html: template.content_html || '',
      active: false,
    });
    useAlert('Modelo duplicado com sucesso.');
    await fetchTemplates();
  } catch (error) {
    useAlert('Erro ao duplicar modelo.');
    console.error('Erro ao duplicar template:', error);
  }
};

const confirmDelete = template => {
  deletingTemplate.value = template;
  showDeleteConfirm.value = true;
};

const cancelDelete = () => {
  showDeleteConfirm.value = false;
  deletingTemplate.value = null;
};

const deleteTemplate = async () => {
  if (!deletingTemplate.value) return;
  try {
    await ContractTemplates.delete(deletingTemplate.value.id);
    useAlert('Modelo excluído com sucesso.');
    cancelDelete();
    await fetchTemplates();
  } catch (error) {
    useAlert('Erro ao excluir modelo.');
    console.error('Erro ao excluir template:', error);
  }
};

onMounted(() => fetchTemplates());
</script>

<template>
  <div class="flex flex-col h-full bg-n-background p-6 overflow-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-n-slate-12">
          Modelos de Contrato
        </h1>
        <p class="text-sm text-n-slate-11 mt-1">
          Gerencie os modelos utilizados na criação de contratos.
        </p>
      </div>
      <Button
        label="+ Novo Modelo"
        color="blue"
        variant="solid"
        size="md"
        @click="openCreateModal"
      />
    </div>

    <!-- Loading -->
    <div
      v-if="isLoading"
      class="flex items-center justify-center py-20"
    >
      <span class="text-n-slate-11">Carregando...</span>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="templates.length === 0"
      class="flex flex-col items-center justify-center py-20 text-center"
    >
      <div
        class="w-16 h-16 rounded-full bg-n-alpha-2 flex items-center justify-center mb-4"
      >
        <svg
          class="w-8 h-8 text-n-slate-11"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="1.5"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
          />
        </svg>
      </div>
      <p class="text-n-slate-11 text-base mb-2">
        Nenhum modelo encontrado.
      </p>
      <p class="text-n-slate-10 text-sm mb-4">
        Crie seu primeiro modelo de contrato.
      </p>
      <Button
        label="+ Novo Modelo"
        color="blue"
        variant="solid"
        size="md"
        @click="openCreateModal"
      />
    </div>

    <!-- Template Cards -->
    <div
      v-else
      class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4"
    >
      <div
        v-for="template in templates"
        :key="template.id"
        class="rounded-xl border border-n-container bg-n-solid-2 p-5 flex flex-col gap-3 hover:border-n-strong transition-colors"
      >
        <!-- Card Header -->
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0 flex-1">
            <h3 class="text-base font-semibold text-n-slate-12 truncate">
              {{ template.name }}
            </h3>
            <p
              v-if="template.description"
              class="text-sm text-n-slate-11 mt-1 line-clamp-2"
            >
              {{ template.description }}
            </p>
          </div>
          <span
            :class="[
              'shrink-0 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
              template.active
                ? 'bg-n-teal-9/10 text-n-teal-11'
                : 'bg-n-slate-9/10 text-n-slate-11',
            ]"
          >
            {{ template.active ? 'Ativo' : 'Inativo' }}
          </span>
        </div>

        <!-- Card Footer -->
        <div class="flex items-center justify-between mt-auto pt-3 border-t border-n-container">
          <span class="text-xs text-n-slate-10">
            Criado em {{ formatDate(template.created_at) }}
          </span>
          <div class="flex items-center gap-1">
            <Button
              label="Editar"
              variant="ghost"
              color="slate"
              size="xs"
              @click="openEditModal(template)"
            />
            <Button
              label="Duplicar"
              variant="ghost"
              color="slate"
              size="xs"
              @click="duplicateTemplate(template)"
            />
            <Button
              label="Excluir"
              variant="ghost"
              color="ruby"
              size="xs"
              @click="confirmDelete(template)"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div
        class="absolute inset-0 bg-black/50"
        @click="closeModal"
      />
      <div
        class="relative w-full max-w-2xl max-h-[90vh] bg-n-solid-2 rounded-xl border border-n-container shadow-xl flex flex-col mx-4"
      >
        <!-- Modal Header -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-n-container">
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ modalTitle }}
          </h2>
          <button
            class="text-n-slate-11 hover:text-n-slate-12 transition-colors"
            @click="closeModal"
          >
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Modal Body -->
        <div class="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Nome
            </label>
            <input
              v-model="formData.name"
              type="text"
              placeholder="Ex: Contrato de Prestação de Serviços"
              class="w-full rounded-lg border border-n-container bg-n-background px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand"
            />
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Descrição
            </label>
            <input
              v-model="formData.description"
              type="text"
              placeholder="Breve descrição do modelo"
              class="w-full rounded-lg border border-n-container bg-n-background px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand"
            />
          </div>

          <!-- Content HTML -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Conteúdo HTML
            </label>
            <p class="text-xs text-n-slate-10 mb-2">
              Use {{variavel}} para variáveis dinâmicas. Ex: {{nome_cliente}}, {{valor}}, {{data_inicio}}
            </p>
            <textarea
              v-model="formData.content_html"
              rows="12"
              placeholder="<h1>Contrato de {{tipo_servico}}</h1>&#10;&#10;<p>Pelo presente instrumento...</p>"
              class="w-full rounded-lg border border-n-container bg-n-background px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-brand font-mono resize-y"
            />
          </div>

          <!-- Active Toggle -->
          <div class="flex items-center gap-3">
            <button
              :class="[
                'relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full transition-colors duration-200',
                formData.active ? 'bg-n-brand' : 'bg-n-alpha-3',
              ]"
              @click="formData.active = !formData.active"
            >
              <span
                :class="[
                  'pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform transition-transform duration-200',
                  formData.active ? 'translate-x-5' : 'translate-x-0.5',
                ]"
                style="margin-top: 2px;"
              />
            </button>
            <span class="text-sm text-n-slate-12">
              {{ formData.active ? 'Ativo' : 'Inativo' }}
            </span>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-n-container">
          <Button
            label="Cancelar"
            variant="ghost"
            color="slate"
            size="md"
            @click="closeModal"
          />
          <Button
            :label="isSaving ? 'Salvando...' : 'Salvar'"
            variant="solid"
            color="blue"
            size="md"
            :is-loading="isSaving"
            :disabled="isSaving"
            @click="saveTemplate"
          />
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="showDeleteConfirm"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div
        class="absolute inset-0 bg-black/50"
        @click="cancelDelete"
      />
      <div
        class="relative w-full max-w-md bg-n-solid-2 rounded-xl border border-n-container shadow-xl mx-4 p-6"
      >
        <h2 class="text-lg font-semibold text-n-slate-12 mb-2">
          Confirmar Exclusão
        </h2>
        <p class="text-sm text-n-slate-11 mb-6">
          Tem certeza que deseja excluir o modelo
          <strong class="text-n-slate-12">{{ deletingTemplate?.name }}</strong>?
          Esta ação não pode ser desfeita.
        </p>
        <div class="flex items-center justify-end gap-2">
          <Button
            label="Cancelar"
            variant="ghost"
            color="slate"
            size="md"
            @click="cancelDelete"
          />
          <Button
            label="Excluir"
            variant="solid"
            color="ruby"
            size="md"
            @click="deleteTemplate"
          />
        </div>
      </div>
    </div>
  </div>
</template>
