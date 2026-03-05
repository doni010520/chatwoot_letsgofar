import ScheduledMessagesAPI from '../../api/scheduledMessages';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

const getters = {
  getScheduledMessages: state => state.records,
  getUIFlags: state => state.uiFlags,
};

const actions = {
  async getAll({ commit }, filters) {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await ScheduledMessagesAPI.getAll(filters);
      commit('setScheduledMessages', response.data);
      return response;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  async create({ commit }, data) {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await ScheduledMessagesAPI.create(data);
      commit('addMessage', response.data);
      return response;
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  async update({ commit }, { id, data }) {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await ScheduledMessagesAPI.update(id, data);
      commit('updateMessage', response.data);
      return response;
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  async delete({ commit }, id) {
    await ScheduledMessagesAPI.delete(id);
    commit('deleteMessage', id);
  },
};

const mutations = {
  setScheduledMessages(state, messages) {
    state.records = messages;
  },

  addMessage(state, message) {
    state.records.push(message);
  },

  updateMessage(state, updatedMessage) {
    const index = state.records.findIndex(msg => msg.id === updatedMessage.id);
    if (index !== -1) {
      state.records[index] = updatedMessage;
    }
  },

  deleteMessage(state, id) {
    state.records = state.records.filter(msg => msg.id !== id);
  },

  setUIFlag(state, flag) {
    state.uiFlags = { ...state.uiFlags, ...flag };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
