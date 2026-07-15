import { frontendURL } from '../../../helper/URLHelper';

const BroadcastsIndex = () => import('./BroadcastsIndex.vue');

const BROADCASTS_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/disparos'),
      name: 'broadcasts_list',
      meta: {
        permissions: BROADCASTS_PERMISSIONS,
      },
      component: BroadcastsIndex,
    },
  ],
};
