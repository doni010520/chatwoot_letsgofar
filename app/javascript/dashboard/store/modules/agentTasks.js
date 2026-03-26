import AgentTasksAPI from '../../api/agentTasks';

const state = {
  tasks: [],
  currentTask: null,
  stats: {
    by_status: { pending: 0, in_progress: 0, completed: 0, cancelled: 0 },
    by_priority: { urgent: 0, high: 0, medium: 0, low: 0 },
    overdue: 0,
    due_today: 0,
    due_this_week: 0,
    unassigned: 0,
    my_tasks: 0,
    total_active: 0,
  },
  calendarData: {},
  kanbanData: {
    pending: [],
    in_progress: [],
    completed: [],
    cancelled: [],
  },
  filters: {
    status: 'active',
    priority: null,
    assigned_to_id: null,
    created_by_id: null,
    due_date: null,
    linked_to: null,
    label_ids: [],
    q: '',
    sort_by: 'priority',
    sort_order: 'desc',
  },
  uiFlags: {
    isLoading: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isFetchingStats: false,
    isFetchingCalendar: false,
    isFetchingKanban: false,
  },
  pagination: {
    currentPage: 1,
    perPage: 25,
    totalCount: 0,
    totalPages: 0,
  },
};

const getters = {
  getTasks: $state => $state.tasks,
  getCurrentTask: $state => $state.currentTask,
  getStats: $state => $state.stats,
  getCalendarData: $state => $state.calendarData,
  getKanbanData: $state => $state.kanbanData,
  getFilters: $state => $state.filters,
  getUIFlags: $state => $state.uiFlags,
  getPagination: $state => $state.pagination,

  getTaskById: $state => id => $state.tasks.find(t => t.id === id),

  getOverdueTasks: $state => $state.tasks.filter(t => t.overdue),

  getTodayTasks: $state => {
    const today = new Date().toISOString().split('T')[0];
    return $state.tasks.filter(t => t.due_date === today);
  },

  getMyTasks: ($state, _getters, _rootState, rootGetters) => {
    const currentUserId = rootGetters.getCurrentUser?.id;
    return $state.tasks.filter(t => t.assigned_to?.id === currentUserId);
  },

  getUnassignedTasks: $state =>
    $state.tasks.filter(t => !t.assigned_to && ['pending', 'in_progress'].includes(t.status)),

  hasActiveFilters: $state => {
    const { status, priority, assigned_to_id, due_date, linked_to, label_ids, q } = $state.filters;
    return (
      (status && status !== 'active') ||
      priority ||
      assigned_to_id ||
      due_date ||
      linked_to ||
      (label_ids && label_ids.length > 0) ||
      q
    );
  },
};

const actions = {
  async fetchTasks({ commit, state: $state }, { filters = {}, page = 1 } = {}) {
    commit('SET_UI_FLAG', { isLoading: true });
    try {
      const mergedFilters = {
        ...$state.filters,
        ...filters,
        page,
        per_page: $state.pagination.perPage,
      };

      const response = await AgentTasksAPI.list(mergedFilters);
      commit('SET_TASKS', response.data.data);
      commit('SET_PAGINATION', response.data.meta);
      return response.data;
    } catch (error) {
      console.error('Error fetching tasks:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isLoading: false });
    }
  },

  async fetchCalendar({ commit }, { startDate, endDate }) {
    commit('SET_UI_FLAG', { isFetchingCalendar: true });
    try {
      const response = await AgentTasksAPI.calendar({ startDate, endDate });
      commit('SET_CALENDAR_DATA', response.data.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching calendar:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetchingCalendar: false });
    }
  },

  async fetchKanban({ commit, state: $state }, filters = {}) {
    commit('SET_UI_FLAG', { isFetchingKanban: true });
    try {
      const mergedFilters = { ...$state.filters, ...filters };
      const response = await AgentTasksAPI.kanban(mergedFilters);
      commit('SET_KANBAN_DATA', response.data.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching kanban:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetchingKanban: false });
    }
  },

  async fetchStats({ commit }) {
    commit('SET_UI_FLAG', { isFetchingStats: true });
    try {
      const response = await AgentTasksAPI.stats();
      commit('SET_STATS', response.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching stats:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetchingStats: false });
    }
  },

  async fetchTask({ commit }, taskId) {
    commit('SET_UI_FLAG', { isLoading: true });
    try {
      const response = await AgentTasksAPI.get(taskId);
      commit('SET_CURRENT_TASK', response.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching task:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isLoading: false });
    }
  },

  async createTask({ commit, dispatch }, taskData) {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const response = await AgentTasksAPI.create(taskData);
      commit('ADD_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error creating task:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },

  async updateTask({ commit, dispatch }, { taskId, taskData }) {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const response = await AgentTasksAPI.update(taskId, taskData);
      commit('UPDATE_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error updating task:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },

  async deleteTask({ commit, dispatch }, taskId) {
    commit('SET_UI_FLAG', { isDeleting: true });
    try {
      await AgentTasksAPI.delete(taskId);
      commit('REMOVE_TASK', taskId);
      dispatch('fetchStats');
    } catch (error) {
      console.error('Error deleting task:', error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isDeleting: false });
    }
  },

  async completeTask({ commit, dispatch }, taskId) {
    try {
      const response = await AgentTasksAPI.complete(taskId);
      commit('UPDATE_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error completing task:', error);
      throw error;
    }
  },

  async startTask({ commit, dispatch }, taskId) {
    try {
      const response = await AgentTasksAPI.start(taskId);
      commit('UPDATE_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error starting task:', error);
      throw error;
    }
  },

  async cancelTask({ commit, dispatch }, taskId) {
    try {
      const response = await AgentTasksAPI.cancel(taskId);
      commit('UPDATE_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error cancelling task:', error);
      throw error;
    }
  },

  async reopenTask({ commit, dispatch }, taskId) {
    try {
      const response = await AgentTasksAPI.reopen(taskId);
      commit('UPDATE_TASK', response.data);
      dispatch('fetchStats');
      return response.data;
    } catch (error) {
      console.error('Error reopening task:', error);
      throw error;
    }
  },

  async assignTask({ commit }, { taskId, userId }) {
    try {
      const response = await AgentTasksAPI.assign(taskId, userId);
      commit('UPDATE_TASK', response.data);
      return response.data;
    } catch (error) {
      console.error('Error assigning task:', error);
      throw error;
    }
  },

  // === ITEMS ===
  async addItem({ commit }, { taskId, title }) {
    try {
      const response = await AgentTasksAPI.addItem(taskId, { title });
      commit('ADD_TASK_ITEM', { taskId, item: response.data });
      return response.data;
    } catch (error) {
      console.error('Error adding item:', error);
      throw error;
    }
  },

  async toggleItem({ commit, dispatch }, { taskId, itemId }) {
    try {
      const response = await AgentTasksAPI.toggleItem(taskId, itemId);
      commit('UPDATE_TASK_ITEM', { taskId, item: response.data });
      
      // Recarrega a tarefa completa para pegar o status atualizado
      await dispatch('fetchTask', taskId);
      
      return response.data;
    } catch (error) {
      console.error('Error toggling item:', error);
      throw error;
    }
  },

  async deleteItem({ commit }, { taskId, itemId }) {
    try {
      await AgentTasksAPI.deleteItem(taskId, itemId);
      commit('REMOVE_TASK_ITEM', { taskId, itemId });
    } catch (error) {
      console.error('Error deleting item:', error);
      throw error;
    }
  },

  async reorderItems({ commit }, { taskId, itemIds }) {
    try {
      const response = await AgentTasksAPI.reorderItems(taskId, itemIds);
      commit('SET_TASK_ITEMS_ORDER', { taskId, items: response.data.items || response.data });
      return response.data;
    } catch (error) {
      console.error('Error reordering items:', error);
      throw error;
    }
  },

  // === COMMENTS ===
  async addComment({ commit }, { taskId, content }) {
    try {
      const response = await AgentTasksAPI.addComment(taskId, content);
      commit('ADD_TASK_COMMENT', { taskId, comment: response.data });
      return response.data;
    } catch (error) {
      console.error('Error adding comment:', error);
      throw error;
    }
  },

  async deleteComment({ commit }, { taskId, commentId }) {
    try {
      await AgentTasksAPI.deleteComment(taskId, commentId);
      commit('REMOVE_TASK_COMMENT', { taskId, commentId });
    } catch (error) {
      console.error('Error deleting comment:', error);
      throw error;
    }
  },

  // === LABELS ===
  async addLabel({ commit }, { taskId, labelId }) {
    try {
      const response = await AgentTasksAPI.addLabel(taskId, labelId);
      commit('ADD_TASK_LABEL', { taskId, label: response.data.label });
      return response.data;
    } catch (error) {
      console.error('Error adding label:', error);
      throw error;
    }
  },

  async removeLabel({ commit }, { taskId, labelId }) {
    try {
      await AgentTasksAPI.removeLabel(taskId, labelId);
      commit('REMOVE_TASK_LABEL', { taskId, labelId });
    } catch (error) {
      console.error('Error removing label:', error);
      throw error;
    }
  },

  // === FILES ===
  async uploadFiles({ commit }, { taskId, files }) {
    try {
      const response = await AgentTasksAPI.uploadFiles(taskId, files);
      commit('UPDATE_TASK', response.data);
      return response.data;
    } catch (error) {
      console.error('Error uploading files:', error);
      throw error;
    }
  },

  async removeFile({ commit }, { taskId, fileId }) {
    try {
      const response = await AgentTasksAPI.removeFile(taskId, fileId);
      commit('UPDATE_TASK', response.data);
      return response.data;
    } catch (error) {
      console.error('Error removing file:', error);
      throw error;
    }
  },

  setFilters({ commit, dispatch }, filters) {
    commit('SET_FILTERS', filters);
    return dispatch('fetchTasks');
  },

  resetFilters({ commit, dispatch }) {
    commit('RESET_FILTERS');
    return dispatch('fetchTasks');
  },

  clearCurrentTask({ commit }) {
    commit('SET_CURRENT_TASK', null);
  },
};

const mutations = {
  SET_TASK_ITEMS_ORDER: ($state, { taskId, items }) => {
    if ($state.currentTask?.id === taskId) {
      $state.currentTask.items = items;
    }
  },
  
  SET_TASKS: ($state, tasks) => {
    $state.tasks = tasks;
  },

  SET_CURRENT_TASK: ($state, task) => {
    $state.currentTask = task;
  },

  SET_STATS: ($state, stats) => {
    $state.stats = stats;
  },

  SET_CALENDAR_DATA: ($state, data) => {
    $state.calendarData = data;
  },

  SET_KANBAN_DATA: ($state, data) => {
    $state.kanbanData = data;
  },

  SET_FILTERS: ($state, filters) => {
    $state.filters = { ...$state.filters, ...filters };
  },

  RESET_FILTERS: $state => {
    $state.filters = {
      status: 'active',
      priority: null,
      assigned_to_id: null,
      created_by_id: null,
      due_date: null,
      linked_to: null,
      label_ids: [],
      q: '',
      sort_by: 'priority',
      sort_order: 'desc',
    };
  },

  SET_PAGINATION: ($state, meta) => {
    $state.pagination = {
      currentPage: meta.current_page,
      perPage: meta.per_page,
      totalCount: meta.total_count,
      totalPages: meta.total_pages,
    };
  },

  SET_UI_FLAG: ($state, flag) => {
    $state.uiFlags = { ...$state.uiFlags, ...flag };
  },

  ADD_TASK: ($state, task) => {
    $state.tasks.unshift(task);
  },

  UPDATE_TASK: ($state, task) => {
    const index = $state.tasks.findIndex(t => t.id === task.id);
    if (index !== -1) {
      $state.tasks.splice(index, 1, task);
    }
    if ($state.currentTask?.id === task.id) {
      $state.currentTask = task;
    }
  },

  REMOVE_TASK: ($state, taskId) => {
    $state.tasks = $state.tasks.filter(t => t.id !== taskId);
    if ($state.currentTask?.id === taskId) {
      $state.currentTask = null;
    }
  },

  ADD_TASK_ITEM: ($state, { taskId, item }) => {
    if ($state.currentTask?.id === taskId) {
      $state.currentTask.items = [...($state.currentTask.items || []), item];
      $state.currentTask.items_count = ($state.currentTask.items_count || 0) + 1;
    }
  },

  UPDATE_TASK_ITEM: ($state, { taskId, item }) => {
    if ($state.currentTask?.id === taskId && $state.currentTask.items) {
      const index = $state.currentTask.items.findIndex(i => i.id === item.id);
      if (index !== -1) {
        $state.currentTask.items.splice(index, 1, item);
      }
      $state.currentTask.items_completed_count = $state.currentTask.items.filter(
        i => i.completed
      ).length;
    }
  },

  REMOVE_TASK_ITEM: ($state, { taskId, itemId }) => {
    if ($state.currentTask?.id === taskId && $state.currentTask.items) {
      const item = $state.currentTask.items.find(i => i.id === itemId);
      $state.currentTask.items = $state.currentTask.items.filter(i => i.id !== itemId);
      $state.currentTask.items_count = Math.max(0, ($state.currentTask.items_count || 1) - 1);
      if (item?.completed) {
        $state.currentTask.items_completed_count = Math.max(
          0,
          ($state.currentTask.items_completed_count || 1) - 1
        );
      }
    }
  },

  ADD_TASK_COMMENT: ($state, { taskId, comment }) => {
    if ($state.currentTask?.id === taskId) {
      $state.currentTask.comments = [...($state.currentTask.comments || []), comment];
      $state.currentTask.comments_count = ($state.currentTask.comments_count || 0) + 1;
    }
  },

  REMOVE_TASK_COMMENT: ($state, { taskId, commentId }) => {
    if ($state.currentTask?.id === taskId && $state.currentTask.comments) {
      $state.currentTask.comments = $state.currentTask.comments.filter(c => c.id !== commentId);
      $state.currentTask.comments_count = Math.max(
        0,
        ($state.currentTask.comments_count || 1) - 1
      );
    }
  },

  ADD_TASK_LABEL: ($state, { taskId, label }) => {
    const updateLabels = task => {
      if (task && task.id === taskId) {
        task.labels = [...(task.labels || []), label];
      }
    };

    updateLabels($state.currentTask);
    const task = $state.tasks.find(t => t.id === taskId);
    updateLabels(task);
  },

  REMOVE_TASK_LABEL: ($state, { taskId, labelId }) => {
    const updateLabels = task => {
      if (task && task.id === taskId && task.labels) {
        task.labels = task.labels.filter(l => l.id !== labelId);
      }
    };

    updateLabels($state.currentTask);
    const task = $state.tasks.find(t => t.id === taskId);
    updateLabels(task);
  },

  MOVE_TASK_KANBAN: ($state, { taskId, fromStatus, toStatus }) => {
    const fromColumn = $state.kanbanData[fromStatus];
    const taskIndex = fromColumn?.findIndex(t => t.id === taskId);

    if (taskIndex !== -1) {
      const [task] = fromColumn.splice(taskIndex, 1);
      task.status = toStatus;
      $state.kanbanData[toStatus].unshift(task);
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
