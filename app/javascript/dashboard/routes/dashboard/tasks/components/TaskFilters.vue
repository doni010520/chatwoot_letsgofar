<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updated']);

const store = useStore();

// Estado local
const isUploading = ref(false);
const isDragging = ref(false);
const fileInput = ref(null);

// Computed
const files = computed(() => props.task.files || []);

// Helpers
const formatFileSize = bytes => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
};

const getFileIcon = contentType => {
  if (contentType?.startsWith('image/')) return 'i-lucide-image';
  if (contentType?.startsWith('video/')) return 'i-lucide-video';
  if (contentType?.startsWith('audio/')) return 'i-lucide-music';
  if (contentType?.includes('pdf')) return 'i-lucide-file-text';
  if (contentType?.includes('spreadsheet') || contentType?.includes('excel')) return 'i-lucide-file-spreadsheet';
  if (contentType?.includes('document') || contentType?.includes('word')) return 'i-lucide-file-type';
  return 'i-lucide-file';
};

// Handlers
const triggerFileInput = () => {
  fileInput.value?.click();
};

const handleFileSelect = async event => {
  const selectedFiles = Array.from(event.target.files || []);
  if (selectedFiles.length === 0) return;
  await uploadFiles(selectedFiles);
  event.target.value = '';
};

const handleDrop = async event => {
  event.preventDefault();
  isDragging.value = false;
  const droppedFiles = Array.from(event.dataTransfer?.files || []);
  if (droppedFiles.length === 0) return;
  await uploadFiles(droppedFiles);
};

const handleDragOver = event => {
  event.preventDefault();
  isDragging.value = true;
};

const handleDragLeave = () => {
  isDragging.value = false;
};

const uploadFiles = async filesToUpload => {
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

const removeFile = async fileId => {
  if (!confirm('Remover este anexo?')) return;
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

const downloadFile = file => {
  window.open(file.url, '_blank');
};
</script>

<template>
  <div class="space-y-3">
    <!-- Drop zone -->
    <div
      class="border-2 border-dashed rounded-lg p-4 text-center transition-colors cursor-pointer"
      :class="[
        isDragging
          ? 'border-n-brand bg-n-brand/5'
          : 'border-n-weak hover:border-n-slate-7',
      ]"
      @click="triggerFileInput"
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
      <div v-if="isUploading" class="flex items-center justify-center gap-2">
        <span class="i-lucide-loader-2 size-5 animate-spin text-n-brand" />
        <span class="text-sm text-n-slate-11">Enviando...</span>
      </div>
      <div v-else class="flex flex-col items-center gap-1">
        <span class="i-lucide-upload size-6 text-n-slate-9" />
        <span class="text-sm text-n-slate-10">
          Clique ou arraste arquivos aqui
        </span>
      </div>
    </div>

    <!-- Lista de arquivos -->
    <div v-if="files.length > 0" class="space-y-2">
      <div
        v-for="file in files"
        :key="file.id"
        class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 group"
      >
        <span :class="getFileIcon(file.content_type)" class="size-5 text-n-slate-9 flex-shrink-0" />
        <div class="flex-1 min-w-0">
          <p class="text-sm text-n-slate-12 truncate">{{ file.filename }}</p>
          <p class="text-xs text-n-slate-10">{{ formatFileSize(file.byte_size) }}</p>
        </div>
        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <Button
            icon="i-lucide-download"
            color="slate"
            size="xs"
            @click.stop="downloadFile(file)"
          />
          <Button
            icon="i-lucide-trash-2"
            color="slate"
            size="xs"
            @click.stop="removeFile(file.id)"
          />
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="text-center py-4">
      <span class="i-lucide-paperclip size-8 text-n-slate-8 mb-2" />
      <p class="text-sm text-n-slate-10">Nenhum anexo</p>
    </div>
  </div>
</template>
