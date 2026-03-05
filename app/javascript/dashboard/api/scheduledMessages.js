import ApiClient from './ApiClient';

class ScheduledMessagesAPI extends ApiClient {
  constructor() {
    super('scheduled_messages', { accountScoped: true });
  }

  getAll(filters = {}) {
    return window.axios.get(this.url, { params: filters });
  }

  create(data) {
    return window.axios.post(this.url, data);
  }

  update(id, data) {
    return window.axios.put(`${this.url}/${id}`, data);
  }

  delete(id) {
    return window.axios.delete(`${this.url}/${id}`);
  }
}

export default new ScheduledMessagesAPI();
