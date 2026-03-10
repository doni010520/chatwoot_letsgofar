<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
  canModify: {
    type: Boolean,
    default: false,
  },
});

const store = useStore();
const { t } = useI18n();

// Estado local
const newComment = ref('');
const isSubmitting = ref(false);

// Computed
const comments = computed(() => props.task.comments || []);
const currentUser = computed(() => store.getters.getCurrentUser);

// Formatar data relativa
const formatRelativeTime = dateString => {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return t('TASKS.COMMENTS.JUST_NOW');
  if (diffMins < 60) return t('TASKS.COMMENTS.MINUTES_AGO', { count: diffMins });
  if (diffHours < 24) return t('TASKS.COMMENTS.HOURS_AGO', { count: diffHours });
  if (diffDays < 7) return t('TASKS.COMMENTS.DAYS_AGO', { count: diffDays });

  return date.toLocaleDateString('pt-BR', {
    day: 'numeric',
    month: 'short',
  });
};

// Handlers
const handleSubmit = async () => {
  if (!newComment.value.trim()) return;

  isSubmitting.value = true;
  try {
    await store.dispatch('agentTasks/addComment', {
      taskId: props.task.id,
      content: newComment.value.trim(),
    });
    newComment.value = '';
  } catch (error) {
    console.error('Error adding comment:', error);
  } finally {
    isSubmitting.value = false;
  }
};

const handleDelete = async comment => {
  if (!confirm(t('TASKS.COMMENTS.CONFIRM_DELETE'))) return;

  try {
    await store.dispatch('agentTasks/deleteComment', {
      taskId: props.task.id,
      commentId: comment.id,
    });
  } catch (error) {
    console.error('Error deleting comment:', error);
  }
};

const canDelete = comment => {
  return comment.user.id === currentUser.value?.id;
};
</script>

<template>
  <div>
    <!-- Lista de comentários -->
    <div class="space-y-4 mb-4">
      <div
        v-for="comment in comments"
        :key="comment.id"
        class="group"
      >
        <div class="flex items-start gap-2">
          <Avatar
            :name="comment.user.name"
            :src="comment.user.avatar_url"
            size="28px"
            class="flex-shrink-0"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-n-slate-12">
                {{ comment.user.name }}
              </span>
              <span class="text-xs text-n-slate-9">
                {{ formatRelativeTime(comment.created_at) }}
              </span>
              <button
                v-if="canDelete(comment)"
                class="opacity-0 group-hover:opacity-100 p-1 text-n-slate-9 hover:text-ruby-9 transition-all"
                @click="handleDelete(comment)"
              >
                <span class="i-lucide-trash-2 size-3" />
              </button>
            </div>
            <p class="text-sm text-n-slate-11 mt-0.5 whitespace-pre-wrap">
              {{ comment.content }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div
      v-if="comments.length === 0"
      class="text-center py-4 text-sm text-n-slate-10"
    >
      {{ t('TASKS.COMMENTS.EMPTY') }}
    </div>

    <!-- Formulário de novo comentário -->
    <div class="flex items-start gap-2 mt-4">
      <Avatar
        :name="currentUser?.name"
        :src="currentUser?.avatar_url"
        size="28px"
        class="flex-shrink-0"
      />
      <div class="flex-1">
        <textarea
          v-model="newComment"
          :placeholder="t('TASKS.COMMENTS.PLACEHOLDER')"
          rows="2"
          class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-background resize-none focus:outline-none focus:ring-2 focus:ring-n-brand disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="isSubmitting || !canModify"
          @keydown.meta.enter="handleSubmit"
          @keydown.ctrl.enter="handleSubmit"
        />
        <div class="flex items-center justify-between mt-2">
          <span class="text-xs text-n-slate-9">
            {{ t('TASKS.COMMENTS.HINT') }}
          </span>
          <button
            class="px-3 py-1.5 text-sm font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand-dark disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            :disabled="!newComment.trim() || isSubmitting || !canModify"
            @click="handleSubmit"
          >
            {{ t('TASKS.COMMENTS.SEND') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
