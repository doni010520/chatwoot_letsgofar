import ApiClient from './ApiClient';

class KanbanAPI extends ApiClient {
  constructor() {
    super('kanban', { accountScoped: true });
  }

  getPipelines(accountId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines`);
  }

  getPipeline(accountId, pipelineId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}`);
  }

  createPipeline(accountId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/kanban/pipelines`, { pipeline: data });
  }

  updatePipeline(accountId, pipelineId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}`, { pipeline: data });
  }

  deletePipeline(accountId, pipelineId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}`);
  }

  getStages(accountId, pipelineId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/stages`);
  }

  createStage(accountId, pipelineId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/stages`, { stage: data });
  }

  updateStage(accountId, pipelineId, stageId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/stages/${stageId}`, { stage: data });
  }

  deleteStage(accountId, pipelineId, stageId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/stages/${stageId}`);
  }

  reorderStage(accountId, pipelineId, stageId, position) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/stages/${stageId}/reorder`, { position });
  }

  getBoard(accountId, pipelineId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/board`);
  }

  moveItem(accountId, pipelineId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/board/move`, data);
  }

  updateConversationStage(accountId, conversationId, stageId) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/update_kanban_stage`, {
      kanban_stage_id: stageId
    });
  }

  updateCrmFields(accountId, conversationId, fields) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/update_crm_fields`, fields);
  }
}

export default new KanbanAPI();
