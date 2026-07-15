import BroadcastsAPI from '../../api/broadcasts';

export const state = {
  records: [],
  current: null,
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getBroadcasts: $state => $state.records,
  getCurrent: $state => $state.current,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  async fetch({ commit }) {
    commit('SET_UI', { isFetching: true });
    try {
      const { data } = await BroadcastsAPI.get();
      commit('SET_ALL', data);
      return data;
    } finally {
      commit('SET_UI', { isFetching: false });
    }
  },

  async show({ commit }, id) {
    const { data } = await BroadcastsAPI.show(id);
    commit('SET_CURRENT', data);
    commit('UPSERT', data);
    return data;
  },

  async create({ commit }, payload) {
    commit('SET_UI', { isCreating: true });
    try {
      const { data } = await BroadcastsAPI.create(payload);
      commit('UPSERT', data);
      return data;
    } finally {
      commit('SET_UI', { isCreating: false });
    }
  },

  async update({ commit }, { id, ...payload }) {
    commit('SET_UI', { isUpdating: true });
    try {
      const { data } = await BroadcastsAPI.update(id, payload);
      commit('UPSERT', data);
      commit('SET_CURRENT', data);
      return data;
    } finally {
      commit('SET_UI', { isUpdating: false });
    }
  },

  async uploadContacts({ commit }, { id, file }) {
    const { data } = await BroadcastsAPI.uploadContacts(id, file);
    commit('SET_CURRENT', data);
    commit('UPSERT', data);
    return data;
  },

  async start({ commit }, id) {
    const { data } = await BroadcastsAPI.start(id);
    commit('SET_CURRENT', data);
    commit('UPSERT', data);
    return data;
  },

  async pause({ commit }, id) {
    const { data } = await BroadcastsAPI.pause(id);
    commit('SET_CURRENT', data);
    commit('UPSERT', data);
    return data;
  },

  async cancel({ commit }, id) {
    const { data } = await BroadcastsAPI.cancel(id);
    commit('SET_CURRENT', data);
    commit('UPSERT', data);
    return data;
  },

  async delete({ commit }, id) {
    await BroadcastsAPI.delete(id);
    commit('REMOVE', id);
  },
};

export const mutations = {
  SET_UI($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
  SET_ALL($state, records) {
    $state.records = records;
  },
  SET_CURRENT($state, record) {
    $state.current = record;
  },
  UPSERT($state, record) {
    const index = $state.records.findIndex(r => r.id === record.id);
    if (index > -1) {
      $state.records.splice(index, 1, record);
    } else {
      $state.records.unshift(record);
    }
  },
  REMOVE($state, id) {
    $state.records = $state.records.filter(r => r.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
