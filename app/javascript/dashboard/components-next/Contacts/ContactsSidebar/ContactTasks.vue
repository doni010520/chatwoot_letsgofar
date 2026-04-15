<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import AgentTasksAPI from 'dashboard/api/agentTasks';

const props = defineProps({
  contactId: {
    type: [String, Number],
    required: true,
  },
});

const route = useRoute();
const router = useRouter();

const tasks = ref([]);
const isLoading = ref(true);

const accountId = computed(() => route.params.accountId);

const activeTasks = computed(() =>
  tasks.value.filter(t => ['pending', 'in_progress'].includes(t.status))
);

const completedTasks = computed(() =>
  tasks.value.filter(t => ['completed', 'cancelled'].includes(t.status))
);

const priorityConfig = {
  urgent: { label: 'Urgente', class: 'bg-ruby-3 text-ruby-11' },
  high: { label: 'Alta', class: 'bg-orange-3 text-orange-11' },
  medium: { label: 'Media', class: 'bg-amber-3 text-amber-11' },
  low: { label: 'Baixa', class: 'bg-green-3 text-green-11' },
};

const statusConfig = {
  pending: { label: 'Pendente', class: 'bg-amber-3 text-amber-11' },
  in_progress: { label: 'Em Andamento', class: 'bg-blue-3 text-blue-11' },
  completed: { label: 'Concluida', class: 'bg-green-3 text-green-11' },
  cancelled: { label: 'Cancelada', class: 'bg-n-slate-3 text-n-slate-11' },
};

const formatDate = dateStr => {
  if (!dateStr) return null;
  const parts = dateStr.split('-');
  const date = new Date(parts[0], parts[1] - 1, parts[2]);
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
};

const isOverdue = task => {
  if (!task.due_date || task.status === 'completed' || task.status === 'cancelled') return false;
  const parts = task.due_date.split('-');
  const dueDate = new Date(parts[0], parts[1] - 1, parts[2]);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return dueDate < today;
};

const goToTasks = () => {
  router.push(`/app/accounts/${accountId.value}/tasks`);
};

const goToTask = task => {
  router.push(`/app/accounts/${accountId.value}/tasks`);
};

const fetchTasks = async () => {
  isLoading.value = true;
  try {
    const response = await AgentTasksAPI.list({
      contact_id: props.contactId,
      per_page: 50,
    });
    tasks.value = response.data.data || [];
  } catch (error) {
    tasks.value = [];
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchTasks);
</script>

<template>
  <div class="flex flex-col gap-4 py-6 px-6">
    <div class="flex items-center justify-between">
      <h3 class="text-sm font-semibold text-n-slate-12">Tarefas</h3>
      <button
        class="text-xs text-n-brand hover:underline"
        @click="goToTasks"
      >
        Ver todas
      </button>
    </div>

    <div
      v-if="isLoading"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <template v-else-if="tasks.length > 0">
      <!-- Tarefas ativas -->
      <div v-if="activeTasks.length > 0" class="flex flex-col gap-2">
        <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wider">
          Ativas ({{ activeTasks.length }})
        </span>
        <div
          v-for="task in activeTasks"
          :key="task.id"
          class="p-3 border rounded-lg cursor-pointer hover:bg-n-alpha-black2 transition-colors"
          :class="{
            'border-ruby-6 bg-ruby-2': isOverdue(task),
            'border-n-weak': !isOverdue(task),
          }"
          @click="goToTask(task)"
        >
          <div class="flex items-start justify-between gap-2">
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-n-slate-12 truncate">
                {{ task.title }}
              </p>
              <div class="flex items-center gap-2 mt-1.5 flex-wrap">
                <!-- Status badge -->
                <span
                  class="px-1.5 py-0.5 text-xs rounded font-medium"
                  :class="(statusConfig[task.status] || statusConfig.pending).class"
                >
                  {{ (statusConfig[task.status] || statusConfig.pending).label }}
                </span>
                <!-- Priority badge -->
                <span
                  class="px-1.5 py-0.5 text-xs rounded"
                  :class="(priorityConfig[task.priority] || priorityConfig.medium).class"
                >
                  {{ (priorityConfig[task.priority] || priorityConfig.medium).label }}
                </span>
                <!-- Due date -->
                <span
                  v-if="task.due_date"
                  class="inline-flex items-center gap-1 text-xs"
                  :class="isOverdue(task) ? 'text-ruby-11 font-bold' : 'text-n-slate-10'"
                >
                  <span class="i-lucide-calendar size-3" />
                  {{ formatDate(task.due_date) }}
                  <span v-if="isOverdue(task)">Atrasada</span>
                </span>
              </div>
            </div>
            <!-- Assignee avatar -->
            <div v-if="task.assigned_to" class="flex-shrink-0">
              <Avatar
                :name="task.assigned_to.name"
                :src="task.assigned_to.avatar_url"
                size="20px"
                :title="task.assigned_to.name"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Tarefas concluidas -->
      <div v-if="completedTasks.length > 0" class="flex flex-col gap-2">
        <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wider">
          Concluidas ({{ completedTasks.length }})
        </span>
        <div
          v-for="task in completedTasks"
          :key="task.id"
          class="p-3 border border-n-weak rounded-lg cursor-pointer hover:bg-n-alpha-black2 transition-colors opacity-60"
          @click="goToTask(task)"
        >
          <div class="flex items-start justify-between gap-2">
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-n-slate-10 truncate line-through">
                {{ task.title }}
              </p>
              <div class="flex items-center gap-2 mt-1.5 flex-wrap">
                <span
                  class="px-1.5 py-0.5 text-xs rounded font-medium"
                  :class="(statusConfig[task.status] || statusConfig.completed).class"
                >
                  {{ (statusConfig[task.status] || statusConfig.completed).label }}
                </span>
                <span
                  v-if="task.due_date"
                  class="inline-flex items-center gap-1 text-xs text-n-slate-10"
                >
                  <span class="i-lucide-calendar size-3" />
                  {{ formatDate(task.due_date) }}
                </span>
              </div>
            </div>
            <div v-if="task.assigned_to" class="flex-shrink-0">
              <Avatar
                :name="task.assigned_to.name"
                :src="task.assigned_to.avatar_url"
                size="20px"
                :title="task.assigned_to.name"
              />
            </div>
          </div>
        </div>
      </div>
    </template>

    <p
      v-else
      class="py-6 text-sm leading-6 text-center text-n-slate-11"
    >
      Nenhuma tarefa vinculada a este contato.
    </p>
  </div>
</template>
