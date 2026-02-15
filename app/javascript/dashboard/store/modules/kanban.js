import KanbanAPI from '../../api/kanban';

const state = {
  pipelines: [],
  currentPipeline: null,
  board: [],
  boardTotals: { count: 0, value: 0 },
  uiFlags: {
    isLoading: false,
    isMoving: false,
  },
};

const getters = {
  getPipelines: $state => $state.pipelines,
  getCurrentPipeline: $state => $state.currentPipeline,
  getBoard: $state => $state.board,
  getBoardTotals: $state => $state.boardTotals,
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  async fetchPipelines({ commit }, accountId) {
    commit('SET_UI_FLAG', { isLoading: true });
    try {
      const response = await KanbanAPI.getPipelines(accountId);
      commit('SET_PIPELINES', response.data);
    } catch (error) {
      console.error('Error fetching pipelines:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isLoading: false });
    }
  },

  async createPipeline({ commit, dispatch }, { accountId, pipelineData }) {
    try {
      const response = await KanbanAPI.createPipeline(accountId, pipelineData);
      dispatch('fetchPipelines', accountId);
      return response.data;
    } catch (error) {
      console.error('Error creating pipeline:', error);
      throw error;
    }
  },

  async updatePipeline({ dispatch }, { accountId, pipelineId, pipelineData }) {
    try {
      await KanbanAPI.updatePipeline(accountId, pipelineId, pipelineData);
      dispatch('fetchPipelines', accountId);
    } catch (error) {
      console.error('Error updating pipeline:', error);
      throw error;
    }
  },

  async deletePipeline({ dispatch }, { accountId, pipelineId }) {
    try {
      await KanbanAPI.deletePipeline(accountId, pipelineId);
      dispatch('fetchPipelines', accountId);
    } catch (error) {
      console.error('Error deleting pipeline:', error);
      throw error;
    }
  },

  async fetchBoard({ commit }, { accountId, pipelineId, filters = {} }) {
    commit('SET_UI_FLAG', { isLoading: true });
    try {
      const response = await KanbanAPI.getBoard(accountId, pipelineId, filters);
      commit('SET_CURRENT_PIPELINE', response.data.pipeline);
      commit('SET_BOARD', response.data.board);
      commit('SET_BOARD_TOTALS', response.data.totals);
      return response.data;
    } catch (error) {
      console.error('Error fetching board:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isLoading: false });
    }
  },

  async moveItem({ commit, state: $state }, { accountId, pipelineId, itemType, itemId, fromStageId, toStageId }) {
    // Optimistic update
    commit('MOVE_ITEM_OPTIMISTIC', { itemType, itemId, fromStageId, toStageId });
    commit('SET_UI_FLAG', { isMoving: true });

    try {
      await KanbanAPI.moveItem(accountId, pipelineId, {
        item_type: itemType,
        item_id: itemId,
        from_stage_id: fromStageId,
        to_stage_id: toStageId,
      });
    } catch (error) {
      // Rollback on error
      commit('MOVE_ITEM_OPTIMISTIC', { itemType, itemId, fromStageId: toStageId, toStageId: fromStageId });
      console.error('Error moving item:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isMoving: false });
    }
  },

  async markAsWon({ commit }, { accountId, conversationId }) {
    try {
      await KanbanAPI.updateCrmFields(accountId, conversationId, { closed_won: true });
      commit('UPDATE_ITEM_STATUS', { itemId: conversationId, closedWon: true, closedReason: null });
    } catch (error) {
      console.error('Error marking as won:', error);
      throw error;
    }
  },

  async markAsLost({ commit }, { accountId, conversationId, reason }) {
    try {
      await KanbanAPI.updateCrmFields(accountId, conversationId, { closed_won: false, closed_reason: reason });
      commit('UPDATE_ITEM_STATUS', { itemId: conversationId, closedWon: false, closedReason: reason });
    } catch (error) {
      console.error('Error marking as lost:', error);
      throw error;
    }
  },

  async createStage({ dispatch }, { accountId, pipelineId, stageData }) {
    try {
      await KanbanAPI.createStage(accountId, pipelineId, stageData);
      dispatch('fetchBoard', { accountId, pipelineId });
    } catch (error) {
      console.error('Error creating stage:', error);
      throw error;
    }
  },

  async updateStage({ dispatch }, { accountId, pipelineId, stageId, stageData }) {
    try {
      await KanbanAPI.updateStage(accountId, pipelineId, stageId, stageData);
      dispatch('fetchBoard', { accountId, pipelineId });
    } catch (error) {
      console.error('Error updating stage:', error);
      throw error;
    }
  },

  async deleteStage({ dispatch }, { accountId, pipelineId, stageId }) {
    try {
      await KanbanAPI.deleteStage(accountId, pipelineId, stageId);
      dispatch('fetchBoard', { accountId, pipelineId });
    } catch (error) {
      console.error('Error deleting stage:', error);
      throw error;
    }
  },

  async reorderStage({ dispatch }, { accountId, pipelineId, stageId, position }) {
    try {
      await KanbanAPI.reorderStage(accountId, pipelineId, stageId, position);
      dispatch('fetchBoard', { accountId, pipelineId });
    } catch (error) {
      console.error('Error reordering stage:', error);
      throw error;
    }
  },

  clearBoard({ commit }) {
    commit('SET_BOARD', []);
    commit('SET_CURRENT_PIPELINE', null);
    commit('SET_BOARD_TOTALS', { count: 0, value: 0 });
  },
};

const mutations = {
  SET_PIPELINES($state, pipelines) {
    $state.pipelines = pipelines;
  },

  SET_CURRENT_PIPELINE($state, pipeline) {
    $state.currentPipeline = pipeline;
  },

  SET_BOARD($state, board) {
    $state.board = board;
  },

  SET_BOARD_TOTALS($state, totals) {
    $state.boardTotals = totals;
  },

  SET_UI_FLAG($state, flag) {
    $state.uiFlags = { ...$state.uiFlags, ...flag };
  },

  MOVE_ITEM_OPTIMISTIC($state, { itemType, itemId, fromStageId, toStageId }) {
    const fromColumn = $state.board.find(col =>
      col.stage.id === fromStageId || (fromStageId === null && col.stage.id === null)
    );
    const toColumn = $state.board.find(col =>
      col.stage.id === toStageId || (toStageId === null && col.stage.id === null)
    );

    if (!fromColumn || !toColumn) return;

    let items = fromColumn.items;
    if (!Array.isArray(items)) {
      items = items[itemType === 'conversation' ? 'conversations' : 'contacts'] || [];
    }

    const itemIndex = items.findIndex(item => item.id === itemId);
    if (itemIndex === -1) return;

    const [movedItem] = items.splice(itemIndex, 1);
    movedItem.kanban_stage_id = toStageId;

    let targetItems = toColumn.items;
    if (!Array.isArray(targetItems)) {
      targetItems = toColumn.items[itemType === 'conversation' ? 'conversations' : 'contacts'] || [];
    }
    targetItems.push(movedItem);

    // Update totals - using deal_value (not value)
    if (fromColumn.totals) {
      fromColumn.totals.count = Math.max(0, (fromColumn.totals.count || 0) - 1);
      fromColumn.totals.value = Math.max(0, (fromColumn.totals.value || 0) - (movedItem.deal_value || 0));
    }
    if (toColumn.totals) {
      toColumn.totals.count = (toColumn.totals.count || 0) + 1;
      toColumn.totals.value = (toColumn.totals.value || 0) + (movedItem.deal_value || 0);
    }
  },

  UPDATE_ITEM_STATUS($state, { itemId, closedWon, closedReason }) {
    // Procura o item em todas as colunas e atualiza
    for (const column of $state.board) {
      let items = column.items;
      if (!Array.isArray(items)) {
        items = items.conversations || [];
      }
      
      const item = items.find(i => i.id === itemId);
      if (item) {
        item.closed_won = closedWon;
        item.closed_reason = closedReason;
        break;
      }
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
