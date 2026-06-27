<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ContactAPI from 'dashboard/api/contacts';
  
const props = defineProps({
  task: {
    type: Object,
    default: null,
  },
});

const removeAttachedFile = async (fileId) => {
  try {
    await store.dispatch('agentTasks/removeFile', {
      taskId: props.task.id,
      fileId,
    });
    
    // Recarregar task do store sem fechar modal
    await store.dispatch('agentTasks/fetchTask', props.task.id);
  } catch (error) {
    console.error('Error removing file:', error);
    alert('Erro ao remover arquivo. Verifique o console.');
  }
};

const openFile = (url) => {
  window.open(url, '_blank');
};

const emit = defineEmits(['close', 'created', 'updated']);

const store = useStore();
const { t } = useI18n();

// Estado do formulário
const formData = ref({
  title: '',
  description: '',
  priority: 'medium',
  status: 'pending',
  due_date: '',
  due_time: '',
  recurrence_type: 'none',
  recurrence_config: { days: [] },
  assigned_to_id: null,
  assigned_to_ids: [],
  contact_id: null,
  conversation_id: null,
  kanban_pipeline_id: null,
  label_ids: [],
});

// Subtarefas
const newItemTitle = ref('');
const items = ref([]);

// ==========================================
// ANEXOS - Upload de arquivos
// ==========================================
const filesToUpload = ref([]);
const fileInput = ref(null);
const isDragging = ref(false);

// ==========================================
// CONTATO - Busca e seleção de contato
// ==========================================
const contactSearchQuery = ref('');
const contactSuggestions = ref([]);
const selectedContact = ref(null);
const isSearchingContacts = ref(false);
const showContactDropdown = ref(false);
let contactSearchTimeout = null;

const searchContacts = async (query) => {
  if (!query || query.length < 2) {
    contactSuggestions.value = [];
    showContactDropdown.value = false;
    return;
  }
  isSearchingContacts.value = true;
  try {
    const response = await ContactAPI.search(query, 1, 'name', '');
    contactSuggestions.value = (response.data.payload || []).slice(0, 8);
    showContactDropdown.value = contactSuggestions.value.length > 0;
  } catch (error) {
    console.error('Error searching contacts:', error);
    contactSuggestions.value = [];
  } finally {
    isSearchingContacts.value = false;
  }
};

const onContactSearchInput = () => {
  clearTimeout(contactSearchTimeout);
  contactSearchTimeout = setTimeout(() => {
    searchContacts(contactSearchQuery.value);
  }, 300);
};

const selectContact = (contact) => {
  selectedContact.value = contact;
  formData.value.contact_id = contact.id;
  contactSearchQuery.value = '';
  contactSuggestions.value = [];
  showContactDropdown.value = false;
};

const clearContact = () => {
  selectedContact.value = null;
  formData.value.contact_id = null;
  contactSearchQuery.value = '';
};

const hideContactDropdown = () => {
  setTimeout(() => {
    showContactDropdown.value = false;
  }, 200);
};

// Auto-fill contact when conversation_id changes
watch(() => formData.value.conversation_id, async (newVal) => {
  if (newVal && !selectedContact.value) {
    try {
      const conversations = store.getters['contactConversations/getConversations'] || [];
      const conv = conversations.find(c => c.id === newVal);
      if (conv?.meta?.sender) {
        const sender = conv.meta.sender;
        selectContact({
          id: sender.id,
          name: sender.name,
          email: sender.email,
          phone_number: sender.phone_number,
          thumbnail: sender.thumbnail,
        });
      }
    } catch (e) {
      // Silently ignore if conversation contact can't be resolved
    }
  }
});
// ==========================================

const openFilePicker = () => {
  fileInput.value?.click();
};

const handleFileSelect = event => {
  const selectedFiles = Array.from(event.target.files || []);
  if (selectedFiles.length > 0) {
    filesToUpload.value = [...filesToUpload.value, ...selectedFiles];
  }
  event.target.value = '';
};

const handleDrop = event => {
  event.preventDefault();
  isDragging.value = false;
  const droppedFiles = Array.from(event.dataTransfer?.files || []);
  if (droppedFiles.length > 0) {
    filesToUpload.value = [...filesToUpload.value, ...droppedFiles];
  }
};

const handleDragOver = event => {
  event.preventDefault();
  isDragging.value = true;
};

const handleDragLeave = () => {
  isDragging.value = false;
};

const removeFile = index => {
  filesToUpload.value.splice(index, 1);
};

const formatFileSize = bytes => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const getFileIcon = file => {
  const type = file.type || '';
  if (type.startsWith('image/')) return 'i-lucide-image';
  if (type.startsWith('video/')) return 'i-lucide-video';
  if (type.startsWith('audio/')) return 'i-lucide-music';
  if (type.includes('pdf')) return 'i-lucide-file-text';
  if (type.includes('spreadsheet') || type.includes('excel')) return 'i-lucide-table';
  if (type.includes('document') || type.includes('word')) return 'i-lucide-file-text';
  return 'i-lucide-file';
};
// ==========================================

// UI Flags
const isSubmitting = ref(false);
const errors = ref({});

// Getters
const agents = computed(() => store.getters['agents/getAgents'] || []);
const labels = computed(() => store.getters['labels/getLabels'] || []);

// É edição?
const isEditing = computed(() => !!props.task);
const modalTitle = computed(() =>
  isEditing.value ? 'Editar Tarefa' : 'Nova Tarefa'
);

// Items visíveis (não deletados)
const visibleItems = computed(() => items.value.filter(i => !i._destroy));

// Opções de prioridade
const priorityOptions = [
  { value: 'low', label: 'Baixa' },
  { value: 'medium', label: 'Média' },
  { value: 'high', label: 'Alta' },
  { value: 'urgent', label: 'Urgente' },
];

// Opções de status
const statusOptions = [
  { value: 'pending', label: 'Pendente' },
  { value: 'in_progress', label: 'Em Andamento' },
  { value: 'completed', label: 'Concluída' },
  { value: 'cancelled', label: 'Cancelada' },
];

// Opções de recorrência
const recurrenceOptions = [
  { value: 'none', label: 'Sem recorrência' },
  { value: 'daily', label: 'Diária' },
  { value: 'weekly', label: 'Semanal' },
  { value: 'monthly', label: 'Mensal' },
  { value: 'custom', label: 'Personalizada' },
];

const weekDays = [
  { value: 0, label: 'Dom' },
  { value: 1, label: 'Seg' },
  { value: 2, label: 'Ter' },
  { value: 3, label: 'Qua' },
  { value: 4, label: 'Qui' },
  { value: 5, label: 'Sex' },
  { value: 6, label: 'Sáb' },
];
  
// Handlers de subtarefas
const addItem = () => {
  if (!newItemTitle.value.trim()) return;

  // Calcular próxima posição baseada nos items existentes
  const maxPosition = items.value.reduce((max, item) => 
    Math.max(max, item.position ?? 0), -1);

  items.value.push({
    id: `new_${Date.now()}`,
    title: newItemTitle.value.trim(),
    completed: false,
    position: maxPosition + 1,
    _new: true,
  });
  newItemTitle.value = '';
};

const removeItem = index => {
  const item = items.value[index];
  if (item._new) {
    items.value.splice(index, 1);
  } else {
    items.value[index]._destroy = true;
  }
};

const toggleLabel = labelId => {
  const index = formData.value.label_ids.indexOf(labelId);
  if (index === -1) {
    formData.value.label_ids.push(labelId);
  } else {
    formData.value.label_ids.splice(index, 1);
  }
};

const validateForm = () => {
  errors.value = {};

  if (!formData.value.title.trim()) {
    errors.value.title = 'O título é obrigatório';
  }

  return Object.keys(errors.value).length === 0;
};

const toggleWeekDay = (day) => {
  const index = formData.value.recurrence_config.days.indexOf(day);
  if (index === -1) {
    formData.value.recurrence_config.days.push(day);
  } else {
    formData.value.recurrence_config.days.splice(index, 1);
  }
};
  
const handleSubmit = async () => {
  if (!validateForm()) return;

  isSubmitting.value = true;

  try {
    const taskData = {
      ...formData.value,
      items_attributes: items.value
        .filter(i => !i._destroy || !i._new)
        .map((i, index) => ({
          id: i._new ? undefined : i.id,
          title: i.title,
          completed: i.completed,
          position: i.position ?? index, // IMPORTANTE: enviar position
          _destroy: i._destroy,
        })),
    };

    if (isEditing.value) {
      await store.dispatch('agentTasks/updateTask', {
        taskId: props.task.id,
        taskData,
      });
      
      // Upload de arquivos se houver (edição)
      if (filesToUpload.value.length > 0) {
        await store.dispatch('agentTasks/uploadFiles', {
          taskId: props.task.id,
          files: filesToUpload.value,
        });
      }
      
      emit('updated');
    } else {
      // CRIAR TAREFA(S) PRIMEIRO — pode ser uma ou várias (multi-responsável)
      const created = await store.dispatch('agentTasks/createTask', taskData);
      const createdTasks = Array.isArray(created) ? created : [created];

      // DEPOIS FAZER UPLOAD DOS ARQUIVOS PARA CADA TAREFA CRIADA
      if (filesToUpload.value.length > 0) {
        await Promise.all(
          createdTasks
            .filter(task => task?.id)
            .map(task =>
              store.dispatch('agentTasks/uploadFiles', {
                taskId: task.id,
                files: filesToUpload.value,
              })
            )
        );
      }

      emit('created', created);
    }
  } catch (error) {
    console.error('Error saving task:', error);
  } finally {
    isSubmitting.value = false;
  }
};

const handleClose = () => {
  emit('close');
};

// Preencher dados se for edição
onMounted(() => {
  if (props.task) {
    formData.value = {
      title: props.task.title || '',
      description: props.task.description || '',
      priority: props.task.priority || 'medium',
      recurrence_type: props.task.recurrence_type || 'none',
      recurrence_config: props.task.recurrence_config || { days: [] }, 
      status: props.task.status || 'pending',
      due_date: props.task.due_date || '',
      due_time: props.task.due_time || '',
      assigned_to_id: props.task.assigned_to?.id || null,
      contact_id: props.task.contact?.id || null,
      conversation_id: props.task.conversation?.id || null,
      kanban_pipeline_id: props.task.kanban_pipeline?.id || null,
      label_ids: props.task.labels?.map(l => l.id) || [],
    };
    // Copiar items COM suas posições
    items.value = (props.task.items || []).map((item, index) => ({
      ...item,
      position: item.position ?? index,
    }));

    // Preencher contato selecionado se existir
    if (props.task.contact) {
      selectedContact.value = props.task.contact;
    }
  }

  store.dispatch('agents/get');
  store.dispatch('labels/get');
});
</script>

<template>
  <Modal :show="true" :on-close="handleClose">
    <div class="p-6 max-h-[85vh] overflow-y-auto">
      <h2 class="text-lg font-medium text-n-slate-12 mb-4">{{ modalTitle }}</h2>
      
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <!-- Título -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            Título *
          </label>
          <input
            v-model="formData.title"
            type="text"
            placeholder="Digite o título da tarefa"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :class="{ 'border-ruby-9': errors.title }"
          />
          <p v-if="errors.title" class="mt-1 text-xs text-ruby-11">{{ errors.title }}</p>
        </div>

        <!-- Descrição -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            Descrição
          </label>
          <textarea
            v-model="formData.description"
            placeholder="Adicione uma descrição (opcional)"
            rows="3"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
          />
        </div>

        <!-- Linha: Responsável + Prioridade -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              {{ isEditing ? 'Responsável' : 'Responsáveis' }}
            </label>
            <!-- Edição: uma tarefa = um responsável -->
            <select
              v-if="isEditing"
              v-model="formData.assigned_to_id"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            >
              <option :value="null">Sem responsável</option>
              <option v-for="agent in agents" :key="agent.id" :value="agent.id">
                {{ agent.name }}
              </option>
            </select>
            <!-- Criação: marque um ou mais; cada pessoa recebe a tarefa no painel dela -->
            <template v-else>
              <div class="max-h-32 overflow-y-auto rounded-lg border border-n-weak bg-n-background p-2 space-y-1">
                <label
                  v-for="agent in agents"
                  :key="agent.id"
                  class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer"
                >
                  <input
                    v-model="formData.assigned_to_ids"
                    type="checkbox"
                    :value="agent.id"
                    class="rounded border-n-weak text-n-brand focus:ring-n-brand"
                  />
                  <span>{{ agent.name }}</span>
                </label>
                <p v-if="agents.length === 0" class="text-xs text-n-slate-10">
                  Nenhum agente disponível.
                </p>
              </div>
              <p class="mt-1 text-xs text-n-slate-10">
                Selecione uma ou mais pessoas. Cada uma recebe uma cópia
                independente da tarefa no painel dela.
              </p>
            </template>
          </div>

          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Prioridade
            </label>
            <select
              v-model="formData.priority"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            >
              <option v-for="opt in priorityOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </div>
        </div>

        <!-- Contato vinculado -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            Contato
          </label>

          <!-- Contato selecionado -->
          <div
            v-if="selectedContact"
            class="flex items-center gap-2 px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1"
          >
            <Avatar
              :name="selectedContact.name"
              :src="selectedContact.thumbnail || selectedContact.avatar_url"
              size="24px"
            />
            <div class="flex-1 min-w-0">
              <span class="text-sm text-n-slate-12 truncate block">
                {{ selectedContact.name }}
              </span>
              <span
                v-if="selectedContact.email || selectedContact.phone_number"
                class="text-xs text-n-slate-10 truncate block"
              >
                {{ selectedContact.email || selectedContact.phone_number }}
              </span>
            </div>
            <button
              type="button"
              class="p-1 text-n-slate-9 hover:text-ruby-9 hover:bg-ruby-500/10 rounded transition-colors"
              @click="clearContact"
            >
              <span class="i-lucide-x size-4" />
            </button>
          </div>

          <!-- Campo de busca de contato -->
          <div v-else class="relative">
            <div class="relative">
              <span class="i-lucide-search size-4 text-n-slate-9 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                v-model="contactSearchQuery"
                type="text"
                placeholder="Buscar contato por nome, e-mail ou telefone..."
                class="w-full pl-9 pr-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand"
                @input="onContactSearchInput"
                @focus="contactSearchQuery.length >= 2 && (showContactDropdown = true)"
                @blur="hideContactDropdown"
              />
              <span
                v-if="isSearchingContacts"
                class="i-lucide-loader-2 size-4 text-n-slate-9 absolute right-3 top-1/2 -translate-y-1/2 animate-spin"
              />
            </div>

            <!-- Dropdown de sugestões -->
            <div
              v-if="showContactDropdown && contactSuggestions.length > 0"
              class="absolute z-50 w-full mt-1 bg-n-background border border-n-weak rounded-lg shadow-lg max-h-48 overflow-y-auto"
            >
              <button
                v-for="contact in contactSuggestions"
                :key="contact.id"
                type="button"
                class="flex items-center gap-2 w-full px-3 py-2 text-left hover:bg-n-alpha-2 transition-colors"
                @mousedown.prevent="selectContact(contact)"
              >
                <Avatar
                  :name="contact.name"
                  :src="contact.thumbnail"
                  size="24px"
                />
                <div class="flex-1 min-w-0">
                  <span class="text-sm text-n-slate-12 truncate block">
                    {{ contact.name }}
                  </span>
                  <span class="text-xs text-n-slate-10 truncate block">
                    {{ contact.email || contact.phone_number || '' }}
                  </span>
                </div>
              </button>
            </div>
          </div>
        </div>

        <!-- Linha: Data + Hora -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Data de Vencimento
            </label>
            <input
              v-model="formData.due_date"
              type="date"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">
              Horário
            </label>
            <input
              v-model="formData.due_time"
              type="time"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            />
          </div>
        </div>

        <!-- Recorrência -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            Recorrência
          </label>
          <select
            v-model="formData.recurrence_type"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option v-for="option in recurrenceOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </div>

        <!-- Dias personalizados -->
        <div v-if="formData.recurrence_type === 'custom'" class="space-y-2">
          <label class="block text-sm font-medium text-n-slate-12">
            Repetir nos dias:
          </label>
          <div class="flex gap-2">
            <button
              v-for="day in weekDays"
              :key="day.value"
              type="button"
              class="px-3 py-1.5 text-sm rounded-lg border transition-colors"
              :class="
                formData.recurrence_config.days.includes(day.value)
                  ? 'bg-blue-500 text-white border-blue-500'
                  : 'border-n-weak text-n-slate-11 hover:border-n-brand'
              "
              @click="toggleWeekDay(day.value)"
            >
              {{ day.label }}
            </button>
          </div>
        </div>

        <!-- Status (apenas em edição) -->
        <div v-if="isEditing">
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            Status
          </label>
          <select
            v-model="formData.status"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-background text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Labels -->
        <div v-if="labels.length > 0">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Labels
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="label in labels"
              :key="label.id"
              type="button"
              class="px-2 py-1 text-xs rounded-full border transition-colors"
              :class="[
                formData.label_ids.includes(label.id)
                  ? 'border-transparent'
                  : 'border-n-weak hover:border-n-slate-7',
              ]"
              :style="{
                backgroundColor: formData.label_ids.includes(label.id) ? label.color : 'transparent',
                color: formData.label_ids.includes(label.id) ? 'white' : label.color,
              }"
              @click="toggleLabel(label.id)"
            >
              {{ label.title }}
            </button>
          </div>
        </div>

        <!-- ==========================================
             ANEXOS - Seção de upload de arquivos
             ========================================== -->
        <div class="border-t border-n-weak pt-4">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            <span class="i-lucide-paperclip size-4 inline-block mr-1 align-text-bottom" />
            Anexos
          </label>
          
          <!-- Área de upload (drag & drop) -->
          <div
            class="border-2 border-dashed rounded-lg p-4 text-center transition-colors cursor-pointer"
            :class="[
              isDragging
                ? 'border-n-brand bg-n-brand/10'
                : 'border-n-weak hover:border-n-brand hover:bg-n-alpha-1',
            ]"
            @click="openFilePicker"
            @drop="handleDrop"
            @dragover="handleDragOver"
            @dragleave="handleDragLeave"
          >
            <input
              ref="fileInput"
              type="file"
              multiple
              class="hidden"
              @change="handleFileSelect"
            />
            <div class="flex flex-col items-center gap-2">
              <span class="i-lucide-upload-cloud size-8 text-n-slate-10" />
              <div class="text-sm text-n-slate-11">
                <span class="text-n-brand font-medium">Clique para selecionar</span>
                ou arraste arquivos aqui
              </div>
              <span class="text-xs text-n-slate-9">PDF, imagens, documentos, etc.</span>
            </div>
          </div>
          
          <!-- Arquivos já anexados (quando editando) -->
          <div v-if="task && task.files && task.files.length > 0" class="mt-3">
            <label class="text-sm font-medium text-n-slate-12 mb-2 block">
              Arquivos anexados
            </label>
            <div class="space-y-2">
              <div
                v-for="file in task.files"
                :key="file.id"
                class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 border border-n-weak"
              >
                <span class="i-lucide-file size-5 text-n-slate-11 flex-shrink-0" />
                <div class="flex-1 min-w-0">
                  <p class="text-sm text-n-slate-12 truncate">{{ file.filename }}</p>
                  <p class="text-xs text-n-slate-10">{{ formatFileSize(file.byte_size) }}</p>
                </div>
                <div class="flex items-center gap-1">
                  <!-- Botão abrir -->
                  <button
                    type="button"
                    class="p-1.5 text-n-slate-9 hover:text-n-brand hover:bg-n-brand/10 rounded transition-colors"
                    @click.stop="openFile(file.url)"
                  >
                    <span class="i-lucide-external-link size-4" />
                  </button>
                  <!-- Botão deletar -->
                  <button
                    type="button"
                    class="p-1.5 text-n-slate-9 hover:text-ruby-9 hover:bg-ruby-500/10 rounded transition-colors"
                    @click.stop="removeAttachedFile(file.id)"
                  >
                    <span class="i-lucide-x size-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
            
          <!-- Lista de arquivos selecionados -->
          <div v-if="filesToUpload.length > 0" class="mt-3 space-y-2">
            <div
              v-for="(file, index) in filesToUpload"
              :key="index"
              class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-2 border border-n-weak"
            >
              <span :class="getFileIcon(file)" class="size-5 text-n-slate-11 flex-shrink-0" />
              <div class="flex-1 min-w-0">
                <p class="text-sm text-n-slate-12 truncate">{{ file.name }}</p>
                <p class="text-xs text-n-slate-10">{{ formatFileSize(file.size) }}</p>
              </div>
              <button
                type="button"
                class="p-1.5 text-n-slate-9 hover:text-ruby-9 hover:bg-ruby-500/10 rounded transition-colors"
                @click.stop="removeFile(index)"
              >
                <span class="i-lucide-x size-4" />
              </button>
            </div>
          </div>
        </div>
        <!-- ========================================== -->

        <!-- Subtarefas -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Subtarefas
          </label>

          <div class="space-y-2">
            <div
              v-for="(item, index) in items.filter(i => !i._destroy)"
              :key="item.id"
              class="flex items-center gap-2"
            >
              <input
                type="checkbox"
                :checked="item.completed"
                class="size-4 rounded border-n-slate-7"
                @change="item.completed = $event.target.checked"
              />
              <input
                v-model="item.title"
                type="text"
                class="flex-1 px-2 py-1 text-sm rounded border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
              />
              <button
                type="button"
                class="p-1 text-n-slate-9 hover:text-ruby-9"
                @click="removeItem(index)"
              >
                <span class="i-lucide-x size-4" />
              </button>
            </div>

            <!-- Adicionar nova subtarefa -->
            <div class="flex items-center gap-2">
              <span class="i-lucide-plus size-4 text-n-slate-9" />
              <input
                v-model="newItemTitle"
                type="text"
                placeholder="Adicionar subtarefa"
                class="flex-1 px-2 py-1 text-sm rounded border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-2 focus:ring-n-brand"
                @keyup.enter="addItem"
              />
              <Button
                type="button"
                color="slate"
                size="xs"
                :disabled="!newItemTitle.trim()"
                @click="addItem"
              >
                Adicionar
              </Button>
            </div>
          </div>
        </div>

        <!-- Ações -->
        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <Button type="button" color="slate" @click="handleClose">
            Cancelar
          </Button>
          <Button type="submit" color="blue" :loading="isSubmitting">
            {{ isEditing ? 'Salvar' : 'Criar Tarefa' }}
          </Button>
        </div>
      </form>
    </div>
  </Modal>
</template>
