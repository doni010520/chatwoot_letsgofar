import { frontendURL } from '../../../helper/URLHelper';

const KanbanIndex = () => import('./Index.vue');
const KanbanDashboard = () => import('./KanbanDashboard.vue');
const KanbanPermissions = () => import('./KanbanPermissions.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/kanban'),
      name: 'kanban_board',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: KanbanIndex,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/dashboard'),
      name: 'kanban_dashboard',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: KanbanDashboard,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/permissions'),
      name: 'kanban_permissions',
      meta: {
        permissions: ['administrator'],
      },
      component: KanbanPermissions,
    },
  ],
};
