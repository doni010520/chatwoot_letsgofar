import { frontendURL } from 'dashboard/helper/URLHelper';

const TasksView = () => import('./TasksView.vue');
const TaskList = () => import('./components/TaskList.vue');
const TaskCalendar = () => import('./components/TaskCalendar.vue');
const TaskKanban = () => import('./components/TaskKanban.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tasks'),
    name: 'tasks_dashboard',
    component: TasksView,
    meta: {
      permissions: ['agent'],
    },
    children: [
      {
        path: '',
        name: 'tasks_list',
        component: TaskList,
        meta: {
          permissions: ['agent'],
        },
      },
      {
        path: 'calendar',
        name: 'tasks_calendar',
        component: TaskCalendar,
        meta: {
          permissions: ['agent'],
        },
      },
      {
        path: 'kanban',
        name: 'tasks_kanban',
        component: TaskKanban,
        meta: {
          permissions: ['agent'],
        },
      },
    ],
  },
];

export default routes;
