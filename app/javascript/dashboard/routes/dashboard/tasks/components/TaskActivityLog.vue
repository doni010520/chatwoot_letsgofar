<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import axios from 'axios';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const activities = ref([]);
const isLoading = ref(true);

const fetchActivities = async () => {
  isLoading.value = true;
  try {
    const response = await axios.get(
      `/api/v1/accounts/${props.task.account_id}/agent_tasks/${props.task.id}/activities`
    );
    activities.value = response.data.data || response.data;
  } catch (error) {
    console.error('Error fetching activities:', error);
  } finally {
    isLoading.value = false;
  }
};

// Agrupar atividades por data
const groupedActivities = computed(() => {
  const groups = {};
  const today = new Date().toDateString();
  const yesterday = new Date(Date.now() - 86400000).toDateString();

  activities.value.forEach(activity => {
    const date = new Date(activity.created_at);
    const dateStr = date.toDateString();
    
    let label;
    if (dateStr === today) {
      label = 'Hoje';
    } else if (dateStr === yesterday) {
      label = 'Ontem';
    } else {
      label = date.toLocaleDateString('pt-BR', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      });
    }

    if (!groups[label]) {
      groups[label] = [];
    }
    groups[label].push(activity);
  });

  return groups;
});

onMounted(() => {
  fetchActivities();
});
</script>

<template>
  <div class="space-y-4">
    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <span class="i-lucide-loader-2 w-5 h-5 animate-spin text-n-slate-10" />
    </div>

    <!-- Empty state -->
    <div
      v-else-if="activities.length === 0"
      class="text-center py-8 text-sm text-n-slate-10"
    >
      Nenhuma atividade registrada.
    </div>

    <!-- Lista de atividades agrupadas por data -->
    <div v-else class="space-y-6">
      <div v-for="(items, dateLabel) in groupedActivities" :key="dateLabel">
        <!-- Data -->
        <div class="flex items-center gap-2 mb-3">
          <span class="i-lucide-calendar w-4 h-4 text-n-slate-9" />
          <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wide">
            {{ dateLabel }}
          </span>
        </div>

        <!-- Atividades do dia -->
        <div class="space-y-2">
          <div
            v-for="activity in items"
            :key="activity.id"
            class="flex items-start gap-3 p-3 rounded-lg bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors"
          >
            <!-- Avatar -->
            <Avatar
              :name="activity.user_name || 'Sistema'"
              :src="activity.user_avatar"
              size="28px"
              class="flex-shrink-0"
            />

            <!-- Conteúdo -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ activity.user_name || 'Sistema' }}
                </span>
                <span class="text-xs text-n-slate-9">
                  {{ activity.formatted_time }}
                </span>
              </div>
              <p class="text-sm text-n-slate-11 mt-0.5">
                {{ activity.description }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
