import ApiClient from './ApiClient';

class BroadcastsAPI extends ApiClient {
  constructor() {
    super('broadcasts', { accountScoped: true });
  }

  create(data) {
    return axios.post(this.url, { broadcast: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { broadcast: data });
  }

  uploadContacts(id, file) {
    const formData = new FormData();
    formData.append('file', file);
    return axios.post(`${this.url}/${id}/upload_contacts`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  start(id) {
    return axios.post(`${this.url}/${id}/start`);
  }

  pause(id) {
    return axios.post(`${this.url}/${id}/pause`);
  }

  cancel(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }
}

export default new BroadcastsAPI();
