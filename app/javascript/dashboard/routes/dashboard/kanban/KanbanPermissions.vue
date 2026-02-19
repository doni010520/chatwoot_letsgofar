<template>
  <div class="permissions-page">
    <header class="permissions-page__header">
      <div class="permissions-page__title">
        <button class="permissions-page__back" @click="goBack">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 12H5M12 19l-7-7 7-7"/>
          </svg>
        </button>
        <span class="permissions-page__icon">🔐</span>
        <h1>Permissões do CRM</h1>
      </div>
    </header>

    <div class="permissions-page__content">
      <CrmPermissionsManager />
    </div>
  </div>
</template>

<script>
import CrmPermissionsManager from 'dashboard/components/kanban/CrmPermissionsManager.vue';

export default {
  name: 'KanbanPermissions',
  components: {
    CrmPermissionsManager,
  },
  computed: {
    accountId() {
      return this.$route.params.accountId;
    },
  },
  methods: {
    goBack() {
      this.$router.push({
        name: 'kanban_board',
        params: { accountId: this.accountId },
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.permissions-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
  background-color: var(--s-25);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 24px;
    background-color: var(--white);
    border-bottom: 1px solid var(--s-100);
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 12px;

    h1 {
      font-size: 18px;
      font-weight: 700;
      color: var(--s-800);
      margin: 0;
    }
  }

  &__back {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 36px;
    height: 36px;
    border: none;
    border-radius: 8px;
    background: var(--s-50);
    cursor: pointer;
    transition: all 0.2s;

    svg {
      width: 20px;
      height: 20px;
      color: var(--s-600);
    }

    &:hover {
      background: var(--s-100);
    }
  }

  &__icon {
    font-size: 24px;
  }

  &__content {
    flex: 1;
    overflow-y: auto;
  }
}

/* Dark mode */
.dark .permissions-page {
  background-color: var(--s-900);

  &__header {
    background-color: #1a1d26;
    border-bottom-color: #2d3343;
  }

  &__title h1 {
    color: var(--s-100);
  }

  &__back {
    background: var(--s-800);

    svg {
      color: var(--s-300);
    }

    &:hover {
      background: var(--s-700);
    }
  }
}
</style>
