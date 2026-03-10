import { frontendURL } from '../../../helper/URLHelper';

const ContractsIndex = () => import('./ContractsIndex.vue');
const ContractCreate = () => import('./ContractCreate.vue');
const ContractView = () => import('./ContractView.vue');
const ContractEdit = () => import('./ContractEdit.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contracts'),
    name: 'contracts_list',
    component: ContractsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/create'),
    name: 'contracts_create',
    component: ContractCreate,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/:contractId'),
    name: 'contracts_view',
    component: ContractView,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/:contractId/edit'),
    name: 'contracts_edit',
    component: ContractEdit,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  // Rotas por status
  {
    path: frontendURL('accounts/:accountId/contracts/status/draft'),
    name: 'contracts_draft',
    component: ContractsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/status/pending'),
    name: 'contracts_pending',
    component: ContractsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/status/signed'),
    name: 'contracts_signed',
    component: ContractsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contracts/status/refused'),
    name: 'contracts_refused',
    component: ContractsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
];

export default {
  routes,
};
