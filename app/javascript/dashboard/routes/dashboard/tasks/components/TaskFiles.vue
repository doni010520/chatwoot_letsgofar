<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updated']);

const store = useStore();
const { t } = useI18n();

const isDragging = ref(false);
const isUploading = ref(false);
const fileInput = ref(null);

const files = computed(() => props.task.files || []);

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const getFileIcon = (contentType) => {
  if (contentType?.startsWith('image/')) return 'i-lucide-image';
  if (contentType?.startsWith('video/')) return 'i-lucide-video';
  if (contentType?.startsWith('audio/')) return 'i-lucide-music';
  if (contentType?.includes('pdf')) return 'i-lucide-file-text';
  if (contentType?.includes('spreadsheet') || contentType?.includes('excel')) return 'i-lucide-table';
  if (contentType?.includes('document') || contentType?.includes('word')) return 'i-lucide-file-text';
  return 'i-lucide-file';
};

const openFilePicker = () => {
  fileInput.value?.click();
};

const handleFileSelect = (event) => {
  const selectedFiles = Array.from(event.target.files);
  if (selectedFiles.length > 0) {
    uploadFiles(selectedFiles);
  }
};

const handleDrop = (event) => {
  isDragging.value = false;
  const droppedFiles = Array.from(event.dataTransfer.files);
  if (droppedFiles.length > 0) {
    uploadFiles(droppedFiles);
  }
};

const uploadFiles = async (filesToUpload) => {
  isUploading.value = true;
  try {
    await store.dispatch('agentTasks/uploadFiles', {
      taskId: props.task.id,
      files: filesToUpload,
    });
    emit('updated');
  } catch (error) {
    console.error('Error uploading files:', error);
  } finally {
    isUploading.value = false;
  }
};

const removeFile = async (fileId) => {
  try {
    await store.dispatch('agentTasks/removeFile', {
      taskId: props.task.id,
      fileId,
    });
    emit('updated');
  } catch (error) {
    console.error('Error removing file:', error);
  }
};

const downloadFile = (file) => {
  window.open(file.url, '_blank');
};
</script>

<template>
  <div class="p-4">
    <!-- Upload Area -->
    <div
      class="relative mb-4 border-2 border-dashed rounded-lg p-6 text-center transition-colors"
      :class="[
        isDragging
          ? 'border-n-brand bg-n-alpha-2'
          : 'border-n-weak hover:border-n-brand',
      ]"
      @dragover.prevent="isDragging = true"
      @dragleave.prevent="isDragging = false"
      @drop.prevent="handleDrop"
    >
      <input
        ref="fileInput"
        type="file"
        multiple
        class="hidden"
        @change="handleFileSelect"
      />
      
      <div v-if="isUploading" class="flex flex-col items-center gap-2">
        <span class="i-lucide-loader-2 size-8 text-n-brand animate-spin" />
        <span class="text-sm text-n-slate-11">Enviando...</span>
      </div>
      
      <div v-else class="flex flex-col items-center gap-2">
        <span class="i-lucide-upload-cloud size-8 text-n-slate-10" />
        <p class="text-sm text-n-slate-11">
          Arraste arquivos aqui ou
          <button
            type="button"
            class="text-n-brand hover:underline"
            @click="openFilePicker"
          >
            clique para selecionar
          </button>
        </p>
      </div>
    </div>

    <!-- File List -->
    <div v-if="files.length > 0" class="space-y-2">
      <div
        v-for="file in files"
        :key="file.id"
        class="flex items-center gap-3 p-3 rounded-lg bg-n-alpha-1 hover:bg-n-alpha-2"
      >
        <span :class="getFileIcon(file.content_type)" class="size-5 text-n-slate-11" />
        
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-n-slate-12 truncate">
            {{ file.filename }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ formatFileSize(file.byte_size) }}
          </p>
        </div>

        <div class="flex items-center gap-1">
          <Button
            icon="i-lucide-download"
            size="xs"
            color="slate"
            @click="downloadFile(file)"
          />
          <Button
            icon="i-lucide-trash-2"
            size="xs"
            color="ruby"
            @click="removeFile(file.id)"
          />
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="text-center py-8 text-n-slate-10"
    >
      <span class="i-lucide-paperclip size-8 mb-2" />
      <p class="text-sm">Nenhum anexo</p>
    </div>
  </div>
</template>
