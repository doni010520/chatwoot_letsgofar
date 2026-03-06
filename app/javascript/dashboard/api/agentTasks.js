import ApiClient from './ApiClient';

class AgentTasksAPI extends ApiClient {
  constructor() {
    super('agent_tasks', { accountScoped: true });
  }

  list(filters = {}) {
    return axios.get(this.url, { params: filters });
  }

  calendar({ startDate, endDate }) {
    return axios.get(`${this.url}/calendar`, {
      params: { start_date: startDate, end_date: endDate },
    });
  }

  stats() {
    return axios.get(`${this.url}/stats`);
  }

  kanban(filters = {}) {
    return axios.get(`${this.url}/kanban`, { params: filters });
  }

  get(taskId) {
    return axios.get(`${this.url}/${taskId}`);
  }

  create(data) {
    return axios.post(this.url, { agent_task: data });
  }

  update(taskId, data) {
    return axios.patch(`${this.url}/${taskId}`, { agent_task: data });
  }

  delete(taskId) {
    return axios.delete(`${this.url}/${taskId}`);
  }

  complete(taskId) {
    return axios.post(`${this.url}/${taskId}/complete`);
  }

  start(taskId) {
    return axios.post(`${this.url}/${taskId}/start`);
  }

  cancel(taskId) {
    return axios.post(`${this.url}/${taskId}/cancel`);
  }

  reopen(taskId) {
    return axios.post(`${this.url}/${taskId}/reopen`);
  }

  assign(taskId, userId) {
    return axios.post(`${this.url}/${taskId}/assign`, { user_id: userId });
  }

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

  getComments(taskId) {
    return axios.get(`${this.url}/${taskId}/comments`);
  }

  addComment(taskId, content) {
    return axios.post(`${this.url}/${taskId}/comments`, { comment: { content } });
  }

  deleteComment(taskId, commentId) {
    return axios.delete(`${this.url}/${taskId}/comments/${commentId}`);
  }

  addLabel(taskId, labelId) {
    return axios.post(`${this.url}/${taskId}/labels`, { label_id: labelId });
  }

  removeLabel(taskId, labelId) {
    return axios.delete(`${this.url}/${taskId}/labels/${labelId}`);
  }

  uploadFiles(taskId, files) {
    const formData = new FormData();
    files.forEach(file => {
      formData.append('agent_task[files][]', file);
    });
    return axios.patch(`${this.url}/${taskId}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  removeFile(taskId, fileId) {
    return axios.delete(`${this.url}/${taskId}/files/${fileId}`);
  }
}

export default new AgentTasksAPI();
