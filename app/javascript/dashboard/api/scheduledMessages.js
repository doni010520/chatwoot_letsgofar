import ApiClient from './ApiClient';

class ScheduledMessagesAPI extends ApiClient {
  constructor() {
    super('scheduled_messages', { accountScoped: true });
  }

  create(data) {
    return window.axios.post(this.url, {
      scheduled_message: data
    });
  }

  getAll(filters = {}) {
    return window.axios.get(this.url, { params: filters });
  }

  delete(id) {
    return window.axios.delete(`${this.url}/${id}`);
  }
}

export default new ScheduledMessagesAPI();
