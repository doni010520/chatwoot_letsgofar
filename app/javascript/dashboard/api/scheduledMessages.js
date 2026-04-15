import ApiClient from './ApiClient';

class ScheduledMessagesAPI extends ApiClient {
  constructor() {
    super('scheduled_messages', { accountScoped: true });
  }

  create(data, files = []) {
    const formData = new FormData();
    formData.append('scheduled_message[contact_id]', data.contact_id);
    formData.append('scheduled_message[content]', data.content);
    formData.append('scheduled_message[scheduled_at]', data.scheduled_at);
    if (data.conversation_id) {
      formData.append(
        'scheduled_message[conversation_id]',
        data.conversation_id
      );
    }
    files.forEach(file => {
      formData.append('scheduled_message[files][]', file);
    });
    return window.axios.post(this.url, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  update(id, data, files = []) {
    const formData = new FormData();
    if (data.content !== undefined) {
      formData.append('scheduled_message[content]', data.content);
    }
    if (data.scheduled_at !== undefined) {
      formData.append('scheduled_message[scheduled_at]', data.scheduled_at);
    }
    if (data.contact_id !== undefined) {
      formData.append('scheduled_message[contact_id]', data.contact_id);
    }
    if (data.conversation_id !== undefined) {
      formData.append(
        'scheduled_message[conversation_id]',
        data.conversation_id
      );
    }
    files.forEach(file => {
      formData.append('scheduled_message[files][]', file);
    });
    return window.axios.patch(`${this.url}/${id}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  getAll(filters = {}) {
    return window.axios.get(this.url, { params: filters });
  }

  delete(id) {
    return window.axios.delete(`${this.url}/${id}`);
  }

  removeFile(messageId, fileId) {
    return window.axios.delete(`${this.url}/${messageId}/files/${fileId}`);
  }
}

export default new ScheduledMessagesAPI();
