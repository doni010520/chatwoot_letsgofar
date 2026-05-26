<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const isEnabled = ref(false);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { auto_agent_prefix_enabled } = currentAccount.value?.settings || {};
    isEnabled.value = !!auto_agent_prefix_enabled;
  },
  { deep: true, immediate: true }
);

const onToggle = async value => {
  try {
    isSubmitting.value = true;
    await updateAccount({ auto_agent_prefix_enabled: value }, { silent: true });
    useAlert(
      value
        ? t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.ENABLED_SUCCESS')
        : t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.DISABLED_SUCCESS')
    );
  } catch (error) {
    isEnabled.value = !value;
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak mt-4"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.TITLE') }}
        </h3>
        <div class="flex justify-end">
          <Switch
            v-model="isEnabled"
            :disabled="isSubmitting"
            @change="onToggle"
          />
        </div>
      </div>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.NOTE') }}
      </p>
      <div
        v-if="isEnabled"
        class="text-xs text-n-slate-11 mt-2 px-3 py-2 rounded-md bg-n-alpha-2 font-mono w-full whitespace-pre-line"
      >
        {{ t('GENERAL_SETTINGS.FORM.AUTO_AGENT_PREFIX.PREVIEW') }}
      </div>
    </div>
  </div>
</template>
