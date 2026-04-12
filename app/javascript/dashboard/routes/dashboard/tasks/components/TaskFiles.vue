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
const expandedVideo = ref(null);

const files = computed(() => props.task.files || []);

const ACCEPTED_FILE_TYPES = [
  'image/*',
  'video/mp4',
  'video/quicktime',
  'video/webm',
  'video/x-msvideo',
  'audio/*',
  'application/pdf',
  '.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.rar,.gz,.txt,.csv',
].join(',');

const isVideo = (contentType) => {
  return contentType?.startsWith('video/');
};

const isImage = (contentType) => {
  return contentType?.startsWith('image/');
};

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

const openFile = (file) => {
  if (isVideo(file.content_type)) {
    expandedVideo.value = file;
    return;
  }
  const link = document.createElement('a');
  link.href = file.url;
  link.target = '_blank';
  link.rel = 'noopener noreferrer';
  link.click();
};

const closeVideoModal = () => {
  expandedVideo.value = null;
};

const handleModalBackdropClick = (event) => {
  if (event.target === event.currentTarget) {
    closeVideoModal();
  }
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
        :accept="ACCEPTED_FILE_TYPES"
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
        <p class="text-xs text-n-slate-9">
          Suporta imagens, videos, PDFs, documentos e mais (max 300MB)
        </p>
      </div>
    </div>

    <!-- File List -->
    <div v-if="files.length > 0" class="space-y-2">
      <div
        v-for="file in files"
        :key="file.id"
        class="rounded-lg bg-n-alpha-1 hover:bg-n-alpha-2 overflow-hidden"
      >
        <!-- Inline Video Player -->
        <div
          v-if="isVideo(file.content_type)"
          class="p-3"
        >
          <video
            :src="file.url"
            controls
            preload="metadata"
            class="w-full max-h-48 rounded-lg bg-n-alpha-black object-contain"
            @click.stop
          >
            Seu navegador nao suporta a tag de video.
          </video>
        </div>

        <!-- File Info Row -->
        <div class="flex items-center gap-3 p-3">
          <span :class="getFileIcon(file.content_type)" class="size-5 text-n-slate-11 shrink-0" />

          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ file.filename }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{ formatFileSize(file.byte_size) }}
              <span v-if="isVideo(file.content_type)" class="ml-1 text-n-slate-9">
                &middot; Video
              </span>
            </p>
          </div>

          <div class="flex items-center gap-1">
            <Button
              v-if="isVideo(file.content_type)"
              icon="i-lucide-maximize-2"
              size="xs"
              color="slate"
              title="Expandir video"
              @click="openFile(file)"
            />
            <Button
              v-else
              icon="i-lucide-eye"
              size="xs"
              color="slate"
              @click="openFile(file)"
            />
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
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="text-center py-8 text-n-slate-10"
    >
      <span class="i-lucide-paperclip size-8 mb-2" />
      <p class="text-sm">Nenhum anexo</p>
    </div>

    <!-- Video Modal -->
    <Teleport to="body">
      <div
        v-if="expandedVideo"
        class="fixed inset-0 z-[9999] flex items-center justify-center bg-n-alpha-black/80 backdrop-blur-sm"
        @click="handleModalBackdropClick"
        @keydown.escape="closeVideoModal"
      >
        <div class="relative w-full max-w-4xl mx-4">
          <!-- Close Button -->
          <button
            type="button"
            class="absolute -top-10 right-0 flex items-center gap-1 text-sm text-n-slate-9 hover:text-n-slate-12 transition-colors"
            @click="closeVideoModal"
          >
            <span class="i-lucide-x size-4" />
            Fechar
          </button>

          <!-- Video Player -->
          <div class="rounded-xl overflow-hidden bg-n-alpha-black shadow-2xl">
            <video
              :src="expandedVideo.url"
              controls
              autoplay
              class="w-full max-h-[80vh] object-contain"
            >
              Seu navegador nao suporta a tag de video.
            </video>

            <!-- Video Info Bar -->
            <div class="flex items-center justify-between px-4 py-3 bg-n-alpha-1">
              <div class="flex items-center gap-2 min-w-0">
                <span class="i-lucide-video size-4 text-n-slate-10 shrink-0" />
                <span class="text-sm text-n-slate-12 truncate">
                  {{ expandedVideo.filename }}
                </span>
                <span class="text-xs text-n-slate-9 shrink-0">
                  {{ formatFileSize(expandedVideo.byte_size) }}
                </span>
              </div>
              <Button
                icon="i-lucide-download"
                size="xs"
                color="slate"
                @click="downloadFile(expandedVideo)"
              />
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
