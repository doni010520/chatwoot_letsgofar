<template>
  <div class="kanban-selector">
    <div class="kanban-selector__field">
      <label>Pipeline</label>
      <select
        v-model="selectedPipelineId"
        class="kanban-selector__select"
        @change="onPipelineChange"
      >
        <option :value="null">Nenhum</option>
        <option
          v-for="pipeline in pipelines"
          :key="pipeline.id"
          :value="pipeline.id"
        >
          {{ pipeline.name }}
        </option>
      </select>
    </div>

    <div v-if="selectedPipelineId && stages.length > 0" class="kanban-selector__field">
      <label>Estágio</label>
      <select
        v-model="selectedStageId"
        class="kanban-selector__select"
        @change="onStageChange"
      >
        <option :value="null">Não atribuído</option>
        <option
          v-for="stage in stages"
          :key="stage.id"
          :value="stage.id"
        >
          {{ stage.name }}
        </option>
      </select>
    </div>

    <div v-if="isSaving" class="kanban-selector__loading">
      Salvando...
    </div>
  </div>
</template>

<script>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

export default {
  name: 'KanbanStageSelector',
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    currentStageId: {
      type: Number,
      default: null,
    },
  },
  emits: ['updated'],
  setup(props, { emit }) {
    const store = useStore();
    const pipelines = ref([]);
    const selectedPipelineId = ref(null);
    const selectedStageId = ref(null);
    const isSaving = ref(false);

    const accountId = computed(() => {
      return store.getters.getCurrentAccountId;
    });

    const stages = computed(() => {
      if (!selectedPipelineId.value) return [];
      const pipeline = pipelines.value.find(p => p.id === selectedPipelineId.value);
      return pipeline?.kanban_stages || [];
    });

    const loadPipelines = async () => {
      try {
        const response = await KanbanAPI.getPipelines(accountId.value);
        pipelines.value = response.data.filter(p => p.pipeline_type === 'conversations');
        
        if (props.currentStageId) {
          for (const pipeline of pipelines.value) {
            const stage = pipeline.kanban_stages?.find(s => s.id === props.currentStageId);
            if (stage) {
              selectedPipelineId.value = pipeline.id;
              selectedStageId.value = props.currentStageId;
              break;
            }
          }
        }
      } catch (error) {
        console.error('Erro ao carregar pipelines:', error);
      }
    };

    const onPipelineChange = () => {
      selectedStageId.value = null;
      if (!selectedPipelineId.value) {
        updateStage(null);
      }
    };

    const onStageChange = () => {
      updateStage(selectedStageId.value);
    };

    const updateStage = async (stageId) => {
      isSaving.value = true;
      try {
        await KanbanAPI.updateConversationStage(
          accountId.value,
          props.conversationId,
          stageId
        );
        emit('updated', stageId);
      } catch (error) {
        console.error('Erro ao atualizar estágio:', error);
      } finally {
        isSaving.value = false;
      }
    };

    watch(() => props.currentStageId, (newVal) => {
      if (newVal !== selectedStageId.value) {
        selectedStageId.value = newVal;
      }
    });

    onMounted(() => {
      loadPipelines();
    });

    return {
      pipelines,
      selectedPipelineId,
      selectedStageId,
      stages,
      isSaving,
      onPipelineChange,
      onStageChange,
    };
  },
};
</script>

<style scoped>
.kanban-selector {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 8px 0;
}

.kanban-selector__field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.kanban-selector__field label {
  font-size: 12px;
  font-weight: 500;
  color: var(--s-600);
}

.kanban-selector__select {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid var(--s-200);
  border-radius: 6px;
  background-color: var(--white);
  color: var(--s-800);
  font-size: 13px;
  cursor: pointer;
}

.kanban-selector__select:focus {
  outline: none;
  border-color: var(--w-500);
}

.kanban-selector__loading {
  font-size: 12px;
  color: var(--s-500);
  text-align: center;
  padding: 4px;
}
</style>
