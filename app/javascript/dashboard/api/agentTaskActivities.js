import ApiClient from './ApiClient';

class AgentTaskActivitiesAPI extends ApiClient {
  constructor() {
    super('agent_tasks', { accountScoped: true });
  }

  getActivities(taskId, params = {}) {
    return axios.get(`${this.url}/${taskId}/activities`, { params });
  }
}

export default new AgentTaskActivitiesAPI();
