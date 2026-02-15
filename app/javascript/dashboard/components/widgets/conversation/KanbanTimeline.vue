<template>
  <div class="kanban-timeline">
    <!-- Tabs -->
    <div class="timeline-tabs">
      <button
        class="timeline-tab"
        :class="{ 'timeline-tab--active': activeTab === 'activities' }"
        @click="activeTab = 'activities'"
      >
        Atividades
      </button>
      <button
        class="timeline-tab"
        :class="{ 'timeline-tab--active': activeTab === 'tasks' }"
        @click="activeTab = 'tasks'"
      >
        Tarefas
        <span v-if="pendingTasksCount > 0" class="timeline-tab__badge">
          {{ pendingTasksCount }}
        </span>
      </button>
    </div>

    <!-- Activities Tab -->
    <div v-if="activeTab === 'activities'" class="timeline-content">
      <!-- Add Activity Button -->
      <button class="timeline-add-btn" @click="showActivityForm = !showActivityForm">
        + Registrar Atividade
      </button>

      <!-- Activity Form -->
      <div v-if="showActivityForm" class="activity-form">
        <select v-model="newActivity.activity_type" class="activity-form__select">
          <option value="call_logged">📞 Ligação</option>
          <option value="email_sent">📧 Email</option>
          <option value="meeting_scheduled">📅 Reunião</option>
          <option value="proposal_sent">📄 Proposta</option>
          <option value="note_added">📝 Nota</option>
          <option value="custom">💬 Outro</option>
        </select>
        <input
          v-model="newActivity.title"
          type="text"
          placeholder="Título..."
          class="activity-form__input"
        />
        <textarea
          v-model="newActivity.description"
          placeholder="Descrição (opcional)..."
          class="activity-form__textarea"
          rows="2"
        />
        <div class="activity-form__actions">
          <button class="btn-cancel" @click="cancelActivity">Cancelar</button>
          <button class="btn-save" @click="saveActivity" :disabled="!newActivity.title">
            Salvar
          </button>
        </div>
      </div>

      <!-- Activities List -->
      <div v-if="isLoadingActivities" class="timeline-loading">Carregando...</div>
      <div v-else-if="activities.length === 0" class="timeline-empty">
        Nenhuma atividade registrada
      </div>
      <div v-else class="activities-list">
        <div v-for="activity in activities" :key="activity.id" class="activity-item">
          <div class="activity-item__icon">{{ getActivityIcon(activity.activity_type) }}</div>
          <div class="activity-item__content">
            <div class="activity-item__title">{{ activity.title }}</div>
            <div v-if="activity.description" class="activity-item__desc">
              {{ activity.description }}
            </div>
            <div class="activity-item__meta">
              <span v-if="activity.user">{{ activity.user.name }}</span>
              <span>{{ formatDate(activity.created_at) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Tasks Tab -->
    <div v-if="activeTab === 'tasks'" class="timeline-content">
      <!-- Add Task Button -->
      <button class="timeline-add-btn" @click="showTaskForm = !showTaskForm">
        + Nova Tarefa
      </button>

      <!-- Task Form -->
      <div v-if="showTaskForm" class="task-form">
        <input
          v-model="newTask.title"
          type="text"
          placeholder="Título da tarefa..."
          class="task-form__input"
        />
        <textarea
          v-model="newTask.description"
          placeholder="Descrição (opcional)..."
          class="task-form__textarea"
          rows="2"
        />
        <div class="task-form__row">
          <div class="task-form__field">
            <label>Vencimento</label>
            <input v-model="newTask.due_at" type="datetime-local" class="task-form__input" />
          </div>
          <div class="task-form__field">
            <label>Prioridade</label>
            <select v-model="newTask.priority" class="task-form__select">
              <option value="low">Baixa</option>
              <option value="medium">Média</option>
              <option value="high">Alta</option>
              <option value="urgent">Urgente</option>
            </select>
          </div>
        </div>
        <div class="task-form__actions">
          <button class="btn-cancel" @click="cancelTask">Cancelar</button>
          <button class="btn-save" @click="saveTask" :disabled="!newTask.title">
            Criar Tarefa
          </button>
        </div>
      </div>

      <!-- Tasks List -->
      <div v-if="isLoadingTasks" class="timeline-loading">Carregando...</div>
      <div v-else-if="tasks.length === 0" class="timeline-empty">
        Nenhuma tarefa criada
      </div>
      <div v-else class="tasks-list">
        <div
          v-for="task in tasks"
          :key="task.id"
          class="task-item"
          :class="{
            'task-item--completed': task.status === 'completed',
            'task-item--overdue': task.overdue
          }"
        >
          <button
            class="task-item__check"
            :class="{ 'task-item__check--done': task.status === 'completed' }"
            @click="toggleTask(task)"
          >
            {{ task.status === 'completed' ? '✓' : '' }}
          </button>
          <div class="task-item__content">
            <div class="task-item__title">{{ task.title }}</div>
            <div v-if="task.description" class="task-item__desc">{{ task.description }}</div>
            <div class="task-item__meta">
              <span
                v-if="task.due_at"
                class="task-item__due"
                :class="{ 'task-item__due--overdue': task.overdue }"
              >
                📅 {{ formatDueDate(task.due_at) }}
              </span>
              <span class="task-item__priority" :class="`task-item__priority--${task.priority}`">
                {{ getPriorityLabel(task.priority) }}
              </span>
            </div>
          </div>
          <button class="task-item__delete" @click="deleteTask(task.id)">✕</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanTimeline',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup(props) {
    const store = useStore();
    const activeTab = ref('tasks');
    const activities = ref([]);
    const tasks = ref([]);
    const isLoadingActivities = ref(false);
    const isLoadingTasks = ref(false);
    const showActivityForm = ref(false);
    const showTaskForm = ref(false);

    const newActivity = ref({
      activity_type: 'note_added',
      title: '',
      description: '',
    });

    const newTask = ref({
      title: '',
      description: '',
      due_at: '',
      priority: 'medium',
    });

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const pendingTasksCount = computed(() => {
      return tasks.value.filter(t => t.status !== 'completed').length;
    });

    const loadActivities = async () => {
      isLoadingActivities.value = true;
      try {
        const response = await KanbanAPI.getActivities(accountId.value, props.conversationId);
        activities.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar atividades:', error);
      } finally {
        isLoadingActivities.value = false;
      }
    };

    const loadTasks = async () => {
      isLoadingTasks.value = true;
      try {
        const response = await KanbanAPI.getTasks(accountId.value, props.conversationId);
        tasks.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar tarefas:', error);
      } finally {
        isLoadingTasks.value = false;
      }
    };

    const saveActivity = async () => {
      if (!newActivity.value.title) return;
      try {
        await KanbanAPI.createActivity(accountId.value, props.conversationId, newActivity.value);
        await loadActivities();
        cancelActivity();
      } catch (error) {
        console.error('Erro ao criar atividade:', error);
      }
    };

    const cancelActivity = () => {
      showActivityForm.value = false;
      newActivity.value = { activity_type: 'note_added', title: '', description: '' };
    };

    const saveTask = async () => {
      if (!newTask.value.title) return;
      try {
        const taskData = { ...newTask.value };
        if (taskData.due_at) {
          taskData.due_at = new Date(taskData.due_at).toISOString();
        } else {
          delete taskData.due_at;
        }
        await KanbanAPI.createTask(accountId.value, props.conversationId, taskData);
        await loadTasks();
        await loadActivities();
        cancelTask();
      } catch (error) {
        console.error('Erro ao criar tarefa:', error);
      }
    };

    const cancelTask = () => {
      showTaskForm.value = false;
      newTask.value = { title: '', description: '', due_at: '', priority: 'medium' };
    };

    const toggleTask = async (task) => {
      try {
        if (task.status === 'completed') {
          await KanbanAPI.updateTask(accountId.value, props.conversationId, task.id, {
            status: 'pending',
            completed_at: null,
          });
        } else {
          await KanbanAPI.completeTask(accountId.value, props.conversationId, task.id);
        }
        await loadTasks();
        await loadActivities();
      } catch (error) {
        console.error('Erro ao atualizar tarefa:', error);
      }
    };

    const deleteTask = async (taskId) => {
      if (!confirm('Excluir esta tarefa?')) return;
      try {
        await KanbanAPI.deleteTask(accountId.value, props.conversationId, taskId);
        await loadTasks();
      } catch (error) {
        console.error('Erro ao excluir tarefa:', error);
      }
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

    const getPriorityLabel = (priority) => {
      const labels = {
        low: 'Baixa',
        medium: 'Média',
        high: 'Alta',
        urgent: 'Urgente',
      };
      return labels[priority] || priority;
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

    const formatDueDate = (dateStr) => {
      const date = new Date(dateStr);
      const now = new Date();
      const diffMs = date - now;
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMs < 0) return 'Atrasada';
      if (diffHours < 1) return 'Em breve';
      if (diffHours < 24) return `Em ${diffHours}h`;
      if (diffDays < 7) return `Em ${diffDays}d`;
      return date.toLocaleDateString('pt-BR');
    };

    onMounted(() => {
      loadActivities();
      loadTasks();
    });

    return {
      activeTab,
      activities,
      tasks,
      isLoadingActivities,
      isLoadingTasks,
      showActivityForm,
      showTaskForm,
      newActivity,
      newTask,
      pendingTasksCount,
      saveActivity,
      cancelActivity,
      saveTask,
      cancelTask,
      toggleTask,
      deleteTask,
      getActivityIcon,
      getPriorityLabel,
      formatDate,
      formatDueDate,
    };
  },
};
</script>

<style scoped>
.kanban-timeline {
  padding: 8px 0;
}

.timeline-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 12px;
}

.timeline-tab {
  flex: 1;
  padding: 8px 12px;
  border: none;
  background-color: var(--s-100);
  color: var(--s-600);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

.timeline-tab:hover {
  background-color: var(--s-200);
}

.timeline-tab--active {
  background-color: var(--w-500);
  color: white;
}

.timeline-tab__badge {
  background-color: #ef4444;
  color: white;
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 10px;
}

.timeline-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.timeline-add-btn {
  width: 100%;
  padding: 10px;
  border: 1px dashed var(--s-300);
  background-color: transparent;
  color: var(--s-600);
  font-size: 13px;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
}

.timeline-add-btn:hover {
  border-color: var(--w-500);
  color: var(--w-500);
  background-color: var(--w-50);
}

.timeline-loading,
.timeline-empty {
  text-align: center;
  padding: 20px;
  color: var(--s-500);
  font-size: 13px;
}

/* Activity Form */
.activity-form,
.task-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  background-color: var(--s-50);
  border-radius: 8px;
}

.activity-form__select,
.activity-form__input,
.activity-form__textarea,
.task-form__select,
.task-form__input,
.task-form__textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  font-size: 13px;
  background-color: white;
}

.activity-form__textarea,
.task-form__textarea {
  resize: none;
}

.task-form__row {
  display: flex;
  gap: 8px;
}

.task-form__field {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.task-form__field label {
  font-size: 11px;
  color: var(--s-600);
}

.activity-form__actions,
.task-form__actions {
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

/* Activities List */
.activities-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
}

.activity-item {
  display: flex;
  gap: 10px;
  padding: 10px;
  background-color: var(--s-50);
  border-radius: 8px;
}

.activity-item__icon {
  font-size: 16px;
  flex-shrink: 0;
}

.activity-item__content {
  flex: 1;
  min-width: 0;
}

.activity-item__title {
  font-size: 13px;
  font-weight: 500;
  color: var(--s-800);
}

.activity-item__desc {
  font-size: 12px;
  color: var(--s-600);
  margin-top: 2px;
}

.activity-item__meta {
  display: flex;
  gap: 8px;
  font-size: 11px;
  color: var(--s-500);
  margin-top: 4px;
}

/* Tasks List */
.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
}

.task-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px;
  background-color: var(--s-50);
  border-radius: 8px;
  border-left: 3px solid var(--s-300);
}

.task-item--completed {
  opacity: 0.6;
  border-left-color: var(--g-500);
}

.task-item--overdue {
  border-left-color: #ef4444;
  background-color: #fef2f2;
}

.task-item__check {
  width: 20px;
  height: 20px;
  border: 2px solid var(--s-400);
  border-radius: 4px;
  background: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  flex-shrink: 0;
}

.task-item__check--done {
  background-color: var(--g-500);
  border-color: var(--g-500);
  color: white;
}

.task-item__content {
  flex: 1;
  min-width: 0;
}

.task-item__title {
  font-size: 13px;
  font-weight: 500;
  color: var(--s-800);
}

.task-item--completed .task-item__title {
  text-decoration: line-through;
}

.task-item__desc {
  font-size: 12px;
  color: var(--s-600);
  margin-top: 2px;
}

.task-item__meta {
  display: flex;
  gap: 8px;
  margin-top: 6px;
}

.task-item__due {
  font-size: 11px;
  color: var(--s-600);
}

.task-item__due--overdue {
  color: #ef4444;
  font-weight: 500;
}

.task-item__priority {
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 500;
}

.task-item__priority--low {
  background-color: var(--s-100);
  color: var(--s-600);
}

.task-item__priority--medium {
  background-color: #dbeafe;
  color: #1e40af;
}

.task-item__priority--high {
  background-color: #fef3c7;
  color: #92400e;
}

.task-item__priority--urgent {
  background-color: #fee2e2;
  color: #991b1b;
}

.task-item__delete {
  background: none;
  border: none;
  color: var(--s-400);
  cursor: pointer;
  font-size: 12px;
  padding: 2px;
}

.task-item__delete:hover {
  color: #ef4444;
}
</style>
