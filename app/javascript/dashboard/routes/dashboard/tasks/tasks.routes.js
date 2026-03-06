import { frontendURL } from '../../../helper/URLHelper';

const TasksIndex = () => import('./TasksIndex.vue');

const TASKS_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tasks'),
      name: 'tasks_list',
      meta: {
        permissions: TASKS_PERMISSIONS,
      },
      component: TasksIndex,
    },
    {
      path: frontendURL('accounts/:accountId/tasks/calendar'),
      name: 'tasks_calendar',
      meta: {
        permissions: TASKS_PERMISSIONS,
      },
      component: TasksIndex,
    },
    {
      path: frontendURL('accounts/:accountId/tasks/kanban'),
      name: 'tasks_kanban',
      meta: {
        permissions: TASKS_PERMISSIONS,
      },
      component: TasksIndex,
    },
  ],
};
