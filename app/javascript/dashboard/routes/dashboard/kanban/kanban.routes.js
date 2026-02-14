import { frontendURL } from '../../../helper/URLHelper';

const KanbanIndex = () => import('./Index.vue');

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
  ],
};