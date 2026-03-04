import ApiClient from './ApiClient';

class AgentTasksAPI extends ApiClient {
  constructor() {
    super('agent_tasks', { accountScoped: true });
  }

  // Listar tarefas com filtros
  list(filters = {}) {
    return axios.get(this.url, { params: filters });
  }

  // Obter dados para o calendário
  calendar({ startDate, endDate }) {
    return axios.get(`${this.url}/calendar`, {
      params: {
        start_date: startDate,
        end_date: endDate,
      },
    });
  }

  // Obter estatísticas
  stats() {
    return axios.get(`${this.url}/stats`);
  }

  // Obter dados para o kanban
  kanban(filters = {}) {
    return axios.get(`${this.url}/kanban`, { params: filters });
  }

  // Obter uma tarefa específica
  get(taskId) {
    return axios.get(`${this.url}/${taskId}`);
  }

  // Criar nova tarefa
  create(data) {
    return axios.post(this.url, { agent_task: data });
  }

  // Atualizar tarefa
  update(taskId, data) {
    return axios.patch(`${this.url}/${taskId}`, { agent_task: data });
  }

  // Deletar tarefa
  delete(taskId) {
    return axios.delete(`${this.url}/${taskId}`);
  }

  // Marcar como concluída
  complete(taskId) {
    return axios.post(`${this.url}/${taskId}/complete`);
  }

  // Iniciar tarefa
  start(taskId) {
    return axios.post(`${this.url}/${taskId}/start`);
  }

  // Cancelar tarefa
  cancel(taskId) {
    return axios.post(`${this.url}/${taskId}/cancel`);
  }

  // Reabrir tarefa
  reopen(taskId) {
    return axios.post(`${this.url}/${taskId}/reopen`);
  }

  // Atribuir tarefa
  assign(taskId, userId) {
    return axios.post(`${this.url}/${taskId}/assign`, { user_id: userId });
  }

  // === ITEMS (Subtarefas) ===

  addItem(taskId, data) {
    return axios.post(`${this.url}/${taskId}/items`, { item: data });
  }

  updateItem(taskId, itemId, data) {
    return axios.patch(`${this.url}/${taskId}/items/${itemId}`, { item: data });
  }

  deleteItem(taskId, itemId) {
    return axios.delete(`${this.url}/${taskId}/items/${itemId}`);
  }

  toggleItem(taskId, itemId) {
    return axios.post(`${this.url}/${taskId}/items/${itemId}/toggle`);
  }

  reorderItems(taskId, itemIds) {
    return axios.post(`${this.url}/${taskId}/items/reorder`, { items: itemIds });
  }

  // === COMMENTS ===

  getComments(taskId) {
    return axios.get(`${this.url}/${taskId}/comments`);
  }

  addComment(taskId, content) {
    return axios.post(`${this.url}/${taskId}/comments`, { comment: { content } });
  }

  deleteComment(taskId, commentId) {
    return axios.delete(`${this.url}/${taskId}/comments/${commentId}`);
  }

  // === LABELS ===

  addLabel(taskId, labelId) {
    return axios.post(`${this.url}/${taskId}/labels`, { label_id: labelId });
  }

  removeLabel(taskId, labelId) {
    return axios.delete(`${this.url}/${taskId}/labels/${labelId}`);
  }
}

export default new AgentTasksAPI();
