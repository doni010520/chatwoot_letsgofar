<template>
  <div class="kanban-tasks">
    <!-- Add Task Button -->
    <button class="tasks-add-btn" @click="showForm = !showForm">
      + Nova Tarefa
    </button>

    <!-- Task Form -->
    <div v-if="showForm" class="task-form">
      <input
        v-model="newTask.title"
        type="text"
        placeholder="O que precisa ser feito?"
        class="task-form__input"
        @keyup.enter="saveTask"
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
          Criar
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="tasks-loading">Carregando...</div>

    <!-- Empty State -->
    <div v-else-if="tasks.length === 0" class="tasks-empty">
      Nenhuma tarefa pendente
    </div>

    <!-- Tasks List -->
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
        <button class="task-item__delete" @click="deleteTaskItem(task.id)">✕</button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanTasks',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  emits: ['task-changed'],
  setup(props, { emit }) {
    const store = useStore();
    const tasks = ref([]);
    const isLoading = ref(false);
    const showForm = ref(false);

    const newTask = ref({
      title: '',
      description: '',
      due_at: '',
      priority: 'medium',
    });

    const accountId = computed(() => store.getters.getCurrentAccountId);

    const loadTasks = async () => {
      isLoading.value = true;
      try {
        const response = await KanbanAPI.getTasks(accountId.value, props.conversationId);
        tasks.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar tarefas:', error);
      } finally {
        isLoading.value = false;
      }
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
        emit('task-changed');
        cancelTask();
      } catch (error) {
        console.error('Erro ao criar tarefa:', error);
      }
    };

    const cancelTask = () => {
      showForm.value = false;
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
        emit('task-changed');
      } catch (error) {
        console.error('Erro ao atualizar tarefa:', error);
      }
    };

    const deleteTaskItem = async (taskId) => {
      if (!confirm('Excluir esta tarefa?')) return;
      try {
        await KanbanAPI.deleteTask(accountId.value, props.conversationId, taskId);
        await loadTasks();
      } catch (error) {
        console.error('Erro ao excluir tarefa:', error);
      }
    };

    const getPriorityLabel = (priority) => {
      const labels = { low: 'Baixa', medium: 'Média', high: 'Alta', urgent: 'Urgente' };
      return labels[priority] || priority;
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

    // Reset tasks when switching conversations
    watch(() => props.conversationId, () => {
      tasks.value = [];
      showForm.value = false;
      loadTasks();
    });

    onMounted(() => {
      loadTasks();
    });

    return {
      tasks,
      isLoading,
      showForm,
      newTask,
      saveTask,
      cancelTask,
      toggleTask,
      deleteTaskItem,
      getPriorityLabel,
      formatDueDate,
    };
  },
};
</script>

<style scoped>
.kanban-tasks {
  padding: 8px 0;
}

.tasks-add-btn {
  width: 100%;
  padding: 10px;
  border: 1px dashed rgb(var(--slate-6));
  background-color: transparent;
  color: rgb(var(--slate-11));
  font-size: 13px;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
  margin-bottom: 12px;
}

.tasks-add-btn:hover {
  border-color: rgb(var(--blue-9));
  color: rgb(var(--blue-9));
  background-color: rgb(var(--blue-2));
}

.tasks-loading,
.tasks-empty {
  text-align: center;
  padding: 20px;
  color: rgb(var(--slate-10));
  font-size: 13px;
}

/* Task Form */
.task-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  background-color: rgb(var(--slate-2));
  border-radius: 8px;
  margin-bottom: 12px;
}

.task-form__input,
.task-form__textarea,
.task-form__select {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid rgb(var(--slate-5));
  border-radius: 6px;
  font-size: 13px;
  background-color: rgb(var(--slate-1));
}

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
  color: rgb(var(--slate-11));
}

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
  border: 1px solid rgb(var(--slate-6));
  color: rgb(var(--slate-11));
}

.btn-save {
  background-color: rgb(var(--blue-9));
  border: none;
  color: white;
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
  background-color: rgb(var(--slate-2));
  border-radius: 8px;
  border-left: 3px solid rgb(var(--slate-6));
}

.task-item--completed {
  opacity: 0.6;
  border-left-color: rgb(var(--teal-9));
}

.task-item--overdue {
  border-left-color: #ef4444;
  background-color: #fef2f2;
}

.task-item__check {
  width: 20px;
  height: 20px;
  border: 2px solid rgb(var(--slate-7));
  border-radius: 4px;
  background: rgb(var(--slate-1));
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  flex-shrink: 0;
}

.task-item__check--done {
  background-color: rgb(var(--teal-9));
  border-color: rgb(var(--teal-9));
  color: white;
}

.task-item__content {
  flex: 1;
  min-width: 0;
}

.task-item__title {
  font-size: 13px;
  font-weight: 500;
  color: rgb(var(--slate-12));
}

.task-item--completed .task-item__title {
  text-decoration: line-through;
}

.task-item__desc {
  font-size: 12px;
  color: rgb(var(--slate-11));
  margin-top: 2px;
}

.task-item__meta {
  display: flex;
  gap: 8px;
  margin-top: 6px;
}

.task-item__due {
  font-size: 11px;
  color: rgb(var(--slate-11));
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
  background-color: rgb(var(--slate-3));
  color: rgb(var(--slate-11));
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
  color: rgb(var(--slate-7));
  cursor: pointer;
  font-size: 12px;
  padding: 2px;
}

.task-item__delete:hover {
  color: #ef4444;
}
</style>
