<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const activities = ref([]);
const isLoading = ref(true);

const fetchActivities = async () => {
  isLoading.value = true;
  try {
    const response = await axios.get(
      `/api/v1/accounts/${props.task.account_id}/agent_tasks/${props.task.id}/activities`
    );
    activities.value = response.data.data || [];
  } catch (error) {
    console.error('Error fetching activities:', error);
  } finally {
    isLoading.value = false;
  }
};

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

    if (!groups[label]) groups[label] = [];
    groups[label].push(activity);
  });

  return groups;
});

onMounted(() => fetchActivities());
</script>

<template>
  <div>
    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <span class="i-lucide-loader-2 w-5 h-5 animate-spin text-n-slate-10" />
    </div>

    <!-- Empty state -->
    <div v-else-if="activities.length === 0" class="text-center py-8 text-sm text-n-slate-10">
      Nenhuma atividade registrada.
    </div>

    <!-- Lista -->
    <div v-else class="space-y-4">
      <div v-for="(items, dateLabel) in groupedActivities" :key="dateLabel">
        <div class="flex items-center gap-2 mb-2">
          <span class="i-lucide-calendar w-3 h-3 text-n-slate-9" />
          <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wide">{{ dateLabel }}</span>
        </div>

        <div class="space-y-2">
          <div
            v-for="activity in items"
            :key="activity.id"
            class="flex items-start gap-2 py-2"
          >
            <Avatar
              :name="activity.user_name || 'Sistema'"
              :src="activity.user_avatar"
              size="24px"
              class="flex-shrink-0"
            />
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-n-slate-12">{{ activity.user_name || 'Sistema' }}</span>
                <span class="text-xs text-n-slate-9">{{ activity.formatted_time }}</span>
              </div>
              <p class="text-sm text-n-slate-11">{{ activity.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
