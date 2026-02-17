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

  getBoard(accountId, pipelineId, filters = {}) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/board`, {
      params: filters
    });
  }

  moveItem(accountId, pipelineId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/board/move`, data);
  }

  // Export
  exportBoard(accountId, pipelineId) {
    return window.axios.get(
      `/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/board/export`,
      { responseType: 'blob' }
    );
  }

  updateConversationStage(accountId, conversationId, stageId) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/update_kanban_stage`, {
      kanban_stage_id: stageId
    });
  }

  updateCrmFields(accountId, conversationId, fields) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/update_crm_fields`, fields);
  }

  // Reports
  getReportSummary(accountId, pipelineId, startDate, endDate) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/reports/summary`, {
      params: { start_date: startDate, end_date: endDate }
    });
  }

  getWonLostByPeriod(accountId, pipelineId, startDate, endDate) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/reports/won_lost_by_period`, {
      params: { start_date: startDate, end_date: endDate }
    });
  }

  getLossReasons(accountId, pipelineId, startDate, endDate) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/reports/loss_reasons`, {
      params: { start_date: startDate, end_date: endDate }
    });
  }

  getTopPerformers(accountId, pipelineId, startDate, endDate) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/reports/top_performers`, {
      params: { start_date: startDate, end_date: endDate }
    });
  }

  // Activities
  getActivities(accountId, conversationId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_activities`);
  }

  createActivity(accountId, conversationId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_activities`, data);
  }

  deleteActivity(accountId, conversationId, activityId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_activities/${activityId}`);
  }

  // Tasks
  getTasks(accountId, conversationId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_tasks`);
  }

  createTask(accountId, conversationId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_tasks`, data);
  }

  updateTask(accountId, conversationId, taskId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_tasks/${taskId}`, data);
  }

  deleteTask(accountId, conversationId, taskId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_tasks/${taskId}`);
  }

  completeTask(accountId, conversationId, taskId) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_tasks/${taskId}/complete`);
  }

  // Custom Fields
  getCustomFields(accountId, pipelineId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/custom_fields`);
  }

  createCustomField(accountId, pipelineId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/custom_fields`, data);
  }

  updateCustomField(accountId, pipelineId, fieldId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/custom_fields/${fieldId}`, data);
  }

  deleteCustomField(accountId, pipelineId, fieldId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/custom_fields/${fieldId}`);
  }

  // Custom Field Values (per conversation)
  getCustomFieldValues(accountId, conversationId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_custom_field_values`);
  }

  updateCustomFieldValues(accountId, conversationId, fields) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_custom_field_values`, { fields });
  }

  bulkUpdateCustomFieldValues(accountId, conversationId, values) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/conversations/${conversationId}/kanban_custom_field_values/bulk_update`, { values });
  }

  // User Tasks (global)
  getUserTasksSummary(accountId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/user_tasks/summary`);
  }

  getUserTasks(accountId, filter = null) {
    const params = filter ? { filter } : {};
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/user_tasks`, { params });
  }

  // ============================================
  // AUTOMATIONS
  // ============================================

  getAutomations(accountId, pipelineId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations`);
  }

  getAutomation(accountId, pipelineId, automationId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}`);
  }

  createAutomation(accountId, pipelineId, data) {
    return window.axios.post(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations`, { automation: data });
  }

  updateAutomation(accountId, pipelineId, automationId, data) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}`, { automation: data });
  }

  deleteAutomation(accountId, pipelineId, automationId) {
    return window.axios.delete(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}`);
  }

  toggleAutomation(accountId, pipelineId, automationId) {
    return window.axios.patch(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}/toggle`);
  }

  getAutomationLogs(accountId, pipelineId, automationId, limit = 50) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}/logs`, { params: { limit } });
  }

  testAutomation(accountId, pipelineId, automationId) {
    return window.axios.post(`/api/v1/accounts/${accountId}/kanban/pipelines/${pipelineId}/automations/${automationId}/test`);
  }

  // ==========================================
  // CRM PERMISSIONS
  // ==========================================

  getCurrentPermissions(accountId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/permissions/current`);
  }

  getAllPermissions(accountId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/permissions`);
  }

  getUserPermissions(accountId, userId) {
    return window.axios.get(`/api/v1/accounts/${accountId}/kanban/permissions/${userId}`);
  }

  updateUserPermissions(accountId, userId, data) {
    return window.axios.put(`/api/v1/accounts/${accountId}/kanban/permissions/${userId}`, data);
  }
}

export default new KanbanAPI();
