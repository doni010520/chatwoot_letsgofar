import { frontendURL } from 'dashboard/helper/URLHelper';

const TasksView = () => import('./TasksView.vue');
const TaskList = () => import('./components/TaskList.vue');
const TaskCalendar = () => import('./components/TaskCalendar.vue');
const TaskKanban = () => import('./components/TaskKanban.vue');

const TASKS_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tasks'),
    name: 'tasks_dashboard',
    component: TasksView,
    meta: {
      permissions: TASKS_PERMISSIONS,
    },
    children: [
      {
        path: '',
        name: 'tasks_list',
        component: TaskList,
        meta: {
          permissions: TASKS_PERMISSIONS,
        },
      },
      {
        path: 'calendar',
        name: 'tasks_calendar',
        component: TaskCalendar,
        meta: {
          permissions: TASKS_PERMISSIONS,
        },
      },
      {
        path: 'kanban',
        name: 'tasks_kanban',
        component: TaskKanban,
        meta: {
          permissions: TASKS_PERMISSIONS,
        },
      },
    ],
  },
];

export default routes;
