<template>
  <div class="kanban-history">
    <!-- Add Note Button -->
    <button class="history-add-btn" @click="showForm = !showForm">
      + Adicionar Nota
    </button>

    <!-- Note Form -->
    <div v-if="showForm" class="note-form">
      <input
        v-model="newNote.title"
        type="text"
        placeholder="Título da nota..."
        class="note-form__input"
      />
      <textarea
        v-model="newNote.description"
        placeholder="Detalhes (opcional)..."
        class="note-form__textarea"
        rows="2"
      />
      <div class="note-form__actions">
        <button class="btn-cancel" @click="cancelNote">Cancelar</button>
        <button class="btn-save" @click="saveNote" :disabled="!newNote.title">
          Salvar
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="history-loading">Carregando...</div>

    <!-- Empty State -->
    <div v-else-if="activities.length === 0" class="history-empty">
      Nenhum registro no histórico
    </div>

    <!-- History List -->
    <div v-else class="history-list">
      <div v-for="activity in activities" :key="activity.id" class="history-item">
        <div class="history-item__icon">{{ getActivityIcon(activity.activity_type) }}</div>
        <div class="history-item__content">
          <div class="history-item__title">{{ activity.title }}</div>
          <div v-if="activity.description" class="history-item__desc">
            {{ activity.description }}
          </div>
          <div class="history-item__meta">
            <span v-if="activity.user" class="history-item__user">{{ activity.user.name }}</span>
            <span class="history-item__time">{{ formatDate(activity.created_at) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanHistory',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup(props) {
    const store = useStore();
    const activities = ref([]);
    const isLoading = ref(false);
    const showForm = ref(false);

    const newNote = ref({
      title: '',
      description: '',
    });

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const loadActivities = async () => {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getActivities(accountId.value, props.conversationId);
        activities.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar histórico:', error);
      } finally {
        isLoading.value = false;
      }
    };

    const saveNote = async () => {
      if (!newNote.value.title) return;
      try {
        await KanbanAPI.createActivity(accountId.value, props.conversationId, {
          activity_type: 'note_added',
          title: newNote.value.title,
          description: newNote.value.description,
        });
        await loadActivities();
        cancelNote();
      } catch (error) {
        console.error('Erro ao criar nota:', error);
      }
    };

    const cancelNote = () => {
      showForm.value = false;
      newNote.value = { title: '', description: '' };
    };

    const getActivityIcon = (type) => {
      const icons = {
        stage_changed: '🔄',
        deal_value_changed: '💰',
        marked_won: '🏆',
        marked_lost: '❌',
        reopened: '🔓',
        note_added: '📝',
        call_logged: '📞',
        email_sent: '📧',
        meeting_scheduled: '📅',
        proposal_sent: '📄',
        task_created: '✅',
        task_completed: '☑️',
        custom: '💬',
      };
      return icons[type] || '📌';
    };

    const formatDate = (dateStr) => {
      const date = new Date(dateStr);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return 'Agora';
      if (diffMins < 60) return `${diffMins}min atrás`;
      if (diffHours < 24) return `${diffHours}h atrás`;
      if (diffDays < 7) return `${diffDays}d atrás`;
      return date.toLocaleDateString('pt-BR');
    };

    // Expor método para refresh externo
    const refresh = () => {
      loadActivities();
    };

    // Reset history when switching conversations
    watch(() => props.conversationId, () => {
      activities.value = [];
      showForm.value = false;
      loadActivities();
    });

    onMounted(() => {
      loadActivities();
    });

    return {
      activities,
      isLoading,
      showForm,
      newNote,
      saveNote,
      cancelNote,
      getActivityIcon,
      formatDate,
      refresh,
    };
  },
};
</script>

<style scoped>
.kanban-history {
  padding: 8px 0;
}

.history-add-btn {
  width: 100%;
  padding: 10px;
  border: 1px dashed var(--s-300);
  background-color: transparent;
  color: var(--s-600);
  font-size: 13px;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
  margin-bottom: 12px;
}

.history-add-btn:hover {
  border-color: var(--w-500);
  color: var(--w-500);
  background-color: var(--w-50);
}

.history-loading,
.history-empty {
  text-align: center;
  padding: 20px;
  color: var(--s-500);
  font-size: 13px;
}

/* Note Form */
.note-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  background-color: var(--s-50);
  border-radius: 8px;
  margin-bottom: 12px;
}

.note-form__input,
.note-form__textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 13px;
  background-color: white;
}

.note-form__textarea {
  resize: none;
}

.note-form__actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 4px;
}

.btn-cancel,
.btn-save {
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
}

.btn-cancel {
  background: none;
  border: 1px solid var(--s-300);
  color: var(--s-600);
}

.btn-save {
  background-color: var(--w-500);
  border: none;
  color: white;
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* History List */
.history-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
}

.history-item {
  display: flex;
  gap: 10px;
  padding: 10px;
  background-color: var(--s-50);
  border-radius: 8px;
}

.history-item__icon {
  font-size: 16px;
  flex-shrink: 0;
}

.history-item__content {
  flex: 1;
  min-width: 0;
}

.history-item__title {
  font-size: 13px;
  font-weight: 500;
  color: var(--s-800);
}

.history-item__desc {
  font-size: 12px;
  color: var(--s-600);
  margin-top: 2px;
}

.history-item__meta {
  display: flex;
  gap: 8px;
  font-size: 11px;
  color: var(--s-500);
  margin-top: 4px;
}

.history-item__user {
  font-weight: 500;
}
</style>
