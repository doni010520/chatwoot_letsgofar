<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import LabelItem from 'dashboard/components-next/Label/LabelItem.vue';
import AddLabel from 'dashboard/components-next/Label/AddLabel.vue';

const props = defineProps({
  contactId: {
    type: [String, Number],
    default: null,
  },
});

const store = useStore();
const route = useRoute();

const showDropdown = ref(false);
const showEditModal = ref(false);
const editingLabel = ref(null);
const editTitle = ref('');
const editColor = ref('#1f93ff');
const isSaving = ref(false);

const hoveredLabel = ref(null);

const allLabels = useMapGetter('labels/getLabels');
const contactLabels = useMapGetter('contactLabels/getContactLabels');

const savedLabels = computed(() => {
  const availableContactLabels = contactLabels.value(props.contactId);
  return allLabels.value.filter(({ title }) =>
    availableContactLabels.includes(title)
  );
});

const labelMenuItems = computed(() => {
  return allLabels.value
    ?.map(label => ({
      label: label.title,
      value: label.id,
      thumbnail: { name: label.title, color: label.color },
      isSelected: savedLabels.value.some(
        savedLabel => savedLabel.id === label.id
      ),
      action: 'contactLabel',
      originalLabel: label,
    }))
    .toSorted((a, b) => Number(a.isSelected) - Number(b.isSelected));
});

const predefinedColors = [
  '#1f93ff', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6',
  '#ec4899', '#06b6d4', '#84cc16', '#f97316', '#6366f1'
];

const fetchLabels = async contactId => {
  if (!contactId) return;
  store.dispatch('contactLabels/get', contactId);
};

const handleLabelAction = async ({ value }) => {
  try {
    const currentLabels = savedLabels.value.map(label => label.title);
    const selectedLabel = allLabels.value.find(label => label.id === value);
    if (!selectedLabel) return;

    let updatedLabels;

    if (currentLabels.includes(selectedLabel.title)) {
      updatedLabels = currentLabels.filter(
        labelTitle => labelTitle !== selectedLabel.title
      );
    } else {
      updatedLabels = [...currentLabels, selectedLabel.title];
    }

    await store.dispatch('contactLabels/update', {
      contactId: props.contactId,
      labels: updatedLabels,
    });

    showDropdown.value = false;
  } catch (error) {
    // error
  }
};

const handleRemoveLabel = label => {
  return handleLabelAction({ value: label.id });
};

const handleCreateLabel = async (title) => {
  if (!title.trim()) return;
  
  isSaving.value = true;
  try {
    // Criar a nova etiqueta
    await store.dispatch('labels/create', {
      title: title.trim(),
      color: predefinedColors[Math.floor(Math.random() * predefinedColors.length)],
      show_on_sidebar: true,
    });

    // Recarregar etiquetas
    await store.dispatch('labels/get');

    // Adicionar ao contato automaticamente
    const currentLabels = savedLabels.value.map(label => label.title);
    await store.dispatch('contactLabels/update', {
      contactId: props.contactId,
      labels: [...currentLabels, title.trim()],
    });
  } catch (error) {
    console.error('Erro ao criar etiqueta:', error);
  } finally {
    isSaving.value = false;
  }
};

const handleEditLabel = (item) => {
  editingLabel.value = item.originalLabel;
  editTitle.value = item.originalLabel.title;
  editColor.value = item.originalLabel.color;
  showEditModal.value = true;
};

const handleEditLabelItem = (label) => {
  editingLabel.value = label;
  editTitle.value = label.title;
  editColor.value = label.color;
  showEditModal.value = true;
};

const saveEditLabel = async () => {
  if (!editTitle.value.trim() || !editingLabel.value) return;

  isSaving.value = true;
  try {
    await store.dispatch('labels/update', {
      id: editingLabel.value.id,
      title: editTitle.value.trim(),
      color: editColor.value,
    });
    await store.dispatch('labels/get');
    closeEditModal();
  } catch (error) {
    console.error('Erro ao editar etiqueta:', error);
  } finally {
    isSaving.value = false;
  }
};

const closeEditModal = () => {
  showEditModal.value = false;
  editingLabel.value = null;
  editTitle.value = '';
  editColor.value = '#1f93ff';
};

watch(
  () => props.contactId,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      fetchLabels(newVal);
    }
  }
);

onMounted(() => {
  if (route.params.contactId) {
    fetchLabels(route.params.contactId);
  }
});

const handleMouseLeave = () => {
  hoveredLabel.value = null;
};

const handleLabelHover = labelId => {
  hoveredLabel.value = labelId;
};
</script>

<template>
  <div class="flex flex-wrap items-center gap-2" @mouseleave="handleMouseLeave">
    <LabelItem
      v-for="label in savedLabels"
      :key="label.id"
      :label="label"
      :is-hovered="hoveredLabel === label.id"
      @remove="handleRemoveLabel"
      @edit="handleEditLabelItem"
      @hover="handleLabelHover(label.id)"
    />
    <AddLabel
      :label-menu-items="labelMenuItems"
      @update-label="handleLabelAction"
      @create-label="handleCreateLabel"
      @edit-label="handleEditLabel"
    />

    <!-- Modal de Edição -->
    <Teleport to="body">
      <div
        v-if="showEditModal"
        class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50"
        @click.self="closeEditModal"
      >
        <div class="bg-n-solid-2 rounded-xl p-6 w-80 shadow-xl">
          <h3 class="text-lg font-semibold text-n-slate-12 mb-4">Editar Etiqueta</h3>
          
          <div class="space-y-4">
            <div>
              <label class="block text-sm text-n-slate-11 mb-1">Nome</label>
              <input
                v-model="editTitle"
                type="text"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:border-n-brand"
                placeholder="Nome da etiqueta"
                @keydown.enter="saveEditLabel"
              />
            </div>
            
            <div>
              <label class="block text-sm text-n-slate-11 mb-2">Cor</label>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="color in predefinedColors"
                  :key="color"
                  type="button"
                  class="size-6 rounded-md transition-transform hover:scale-110"
                  :class="{ 'ring-2 ring-n-brand ring-offset-2 ring-offset-n-solid-2': editColor === color }"
                  :style="{ backgroundColor: color }"
                  @click="editColor = color"
                />
              </div>
            </div>
          </div>

          <div class="flex gap-2 mt-6 justify-end">
            <button
              type="button"
              class="px-4 py-2 text-sm rounded-lg bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3"
              @click="closeEditModal"
            >
              Cancelar
            </button>
            <button
              type="button"
              class="px-4 py-2 text-sm rounded-lg bg-n-brand text-white hover:bg-n-brand/90 disabled:opacity-50"
              :disabled="!editTitle.trim() || isSaving"
              @click="saveEditLabel"
            >
              {{ isSaving ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
