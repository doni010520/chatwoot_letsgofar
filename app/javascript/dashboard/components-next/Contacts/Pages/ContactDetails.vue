<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';
import Policy from 'dashboard/components/policy.vue';
import ContactAPI from 'dashboard/api/contacts';
import KanbanAPI from 'dashboard/api/kanban';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const confirmDeleteContactDialogRef = ref(null);

const avatarFile = ref(null);
const avatarUrl = ref('');

const contactsFormRef = ref(null);

const uiFlags = useMapGetter('contacts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const contactData = ref({});

// CRM Modal state
const showCrmModal = ref(false);
const crmPipelines = ref([]);
const crmStages = ref([]);
const selectedPipelineId = ref(null);
const selectedStageId = ref(null);
const crmDealValue = ref('');
const isAddingToCrm = ref(false);
const isLoadingPipelines = ref(false);
const isLoadingStages = ref(false);

const accountId = computed(() => route.params.accountId);

const contactConversations = useMapGetter(
  'contactConversations/getContactConversation'
);

const hasCrmData = computed(() => {
  const conversations = contactConversations.value(props.selectedContact?.id);
  if (!conversations || !conversations.length) return false;
  return conversations.some(c => c.kanban_stage_id);
});

const fetchPipelines = async () => {
  isLoadingPipelines.value = true;
  try {
    const response = await KanbanAPI.getPipelines(accountId.value);
    crmPipelines.value = response.data || [];
  } catch (error) {
    console.error('Error fetching pipelines:', error);
  } finally {
    isLoadingPipelines.value = false;
  }
};

const fetchStages = async pipelineId => {
  if (!pipelineId) {
    crmStages.value = [];
    return;
  }
  isLoadingStages.value = true;
  try {
    const response = await KanbanAPI.getStages(accountId.value, pipelineId);
    crmStages.value = response.data || [];
  } catch (error) {
    console.error('Error fetching stages:', error);
  } finally {
    isLoadingStages.value = false;
  }
};

watch(selectedPipelineId, newVal => {
  selectedStageId.value = null;
  fetchStages(newVal);
});

const openCrmModal = async () => {
  showCrmModal.value = true;
  selectedPipelineId.value = null;
  selectedStageId.value = null;
  crmDealValue.value = '';
  await fetchPipelines();
};

const closeCrmModal = () => {
  showCrmModal.value = false;
};

const submitAddToCrm = async () => {
  if (!selectedPipelineId.value || !selectedStageId.value) {
    useAlert('Selecione o pipeline e o estágio.');
    return;
  }
  isAddingToCrm.value = true;
  try {
    await ContactAPI.addToCrm(props.selectedContact.id, {
      pipeline_id: selectedPipelineId.value,
      stage_id: selectedStageId.value,
      deal_value: crmDealValue.value || null,
    });
    useAlert('Contato adicionado ao CRM com sucesso!');
    closeCrmModal();
    // Refresh conversations to update hasCrmData
    store.dispatch('contactConversations/get', props.selectedContact.id);
  } catch (error) {
    useAlert('Erro ao adicionar contato ao CRM.');
  } finally {
    isAddingToCrm.value = false;
  }
};

const getInitialContactData = () => {
  if (!props.selectedContact) return {};
  return { ...props.selectedContact };
};

onMounted(() => {
  Object.assign(contactData.value, getInitialContactData());
});

const createdAt = computed(() => {
  return contactData.value?.createdAt
    ? dynamicTime(contactData.value.createdAt)
    : '';
});

const lastActivityAt = computed(() => {
  return contactData.value?.lastActivityAt
    ? dynamicTime(contactData.value.lastActivityAt)
    : '';
});

const avatarSrc = computed(() => {
  return avatarUrl.value ? avatarUrl.value : contactData.value?.thumbnail;
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const updateContact = async () => {
  try {
    const { customAttributes, ...basicContactData } = contactData.value;
    await store.dispatch('contacts/update', basicContactData);
    await store.dispatch(
      'contacts/fetchContactableInbox',
      props.selectedContact.id
    );
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.ERROR_MESSAGE'));
  }
};

const openConfirmDeleteContactDialog = () => {
  confirmDeleteContactDialogRef.value?.dialogRef.open();
};

const handleAvatarUpload = async ({ file, url }) => {
  avatarFile.value = file;
  avatarUrl.value = url;

  try {
    await store.dispatch('contacts/update', {
      ...contactsFormRef.value?.state,
      avatar: file,
      isFormData: true,
    });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.ERROR_MESSAGE'));
  }
};

const handleAvatarDelete = async () => {
  try {
    if (props.selectedContact && props.selectedContact.id) {
      await store.dispatch('contacts/deleteAvatar', props.selectedContact.id);
      useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.SUCCESS_MESSAGE'));
    }
    avatarFile.value = null;
    avatarUrl.value = '';
    contactData.value.thumbnail = null;
  } catch (error) {
    useAlert(
      error.message
        ? error.message
        : t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <div class="flex flex-col items-start gap-8 pb-6">
    <div class="flex flex-col items-start gap-3">
      <Avatar
        :src="avatarSrc || ''"
        :name="selectedContact?.name || ''"
        :size="72"
        allow-upload
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ selectedContact?.name }}
        </h3>
        <div class="flex flex-col gap-1.5">
          <span
            v-if="selectedContact?.identifier"
            class="inline-flex items-center gap-1 text-sm text-n-slate-11"
          >
            <span class="i-ph-user-gear text-n-slate-10 size-4" />
            {{ selectedContact?.identifier }}
          </span>
          <span class="inline-flex items-center gap-1 text-sm text-n-slate-11">
            <span
              v-if="selectedContact?.identifier"
              class="i-ph-activity text-n-slate-10 size-4"
            />
            {{ $t('CONTACTS_LAYOUT.DETAILS.CREATED_AT', { date: createdAt }) }}
            •
            {{
              $t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
                date: lastActivityAt,
              })
            }}
          </span>
        </div>
      </div>
      <ContactLabels :contact-id="selectedContact?.id" />
    </div>

    <!-- Adicionar ao CRM button -->
    <div v-if="!hasCrmData" class="w-full">
      <Button
        label="Adicionar ao CRM"
        size="sm"
        icon="i-lucide-kanban"
        @click="openCrmModal"
      />
    </div>

    <!-- CRM Modal (inline) -->
    <Teleport to="body">
      <div
        v-if="showCrmModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
        @click.self="closeCrmModal"
      >
        <div
          class="bg-n-solid-2 rounded-xl shadow-xl w-full max-w-md mx-4 p-6 flex flex-col gap-5"
        >
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-n-slate-12">
              Adicionar ao CRM
            </h3>
            <button
              class="text-n-slate-11 hover:text-n-slate-12"
              @click="closeCrmModal"
            >
              <span class="i-lucide-x size-5" />
            </button>
          </div>

          <div class="flex flex-col gap-4">
            <!-- Pipeline select -->
            <div class="flex flex-col gap-1.5">
              <label class="text-sm font-medium text-n-slate-11">
                Pipeline
              </label>
              <select
                v-model="selectedPipelineId"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
                :disabled="isLoadingPipelines"
              >
                <option :value="null" disabled>
                  {{ isLoadingPipelines ? 'Carregando...' : 'Selecione um pipeline' }}
                </option>
                <option
                  v-for="pipeline in crmPipelines"
                  :key="pipeline.id"
                  :value="pipeline.id"
                >
                  {{ pipeline.name }}
                </option>
              </select>
            </div>

            <!-- Stage select -->
            <div class="flex flex-col gap-1.5">
              <label class="text-sm font-medium text-n-slate-11">
                Estágio
              </label>
              <select
                v-model="selectedStageId"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
                :disabled="!selectedPipelineId || isLoadingStages"
              >
                <option :value="null" disabled>
                  {{ isLoadingStages ? 'Carregando...' : 'Selecione um estágio' }}
                </option>
                <option
                  v-for="stage in crmStages"
                  :key="stage.id"
                  :value="stage.id"
                >
                  {{ stage.name }}
                </option>
              </select>
            </div>

            <!-- Deal value -->
            <div class="flex flex-col gap-1.5">
              <label class="text-sm font-medium text-n-slate-11">
                Valor do negócio (opcional)
              </label>
              <input
                v-model="crmDealValue"
                type="number"
                step="0.01"
                min="0"
                placeholder="R$ 0,00"
                class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
              />
            </div>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <Button
              label="Cancelar"
              size="sm"
              slate
              @click="closeCrmModal"
            />
            <Button
              label="Adicionar"
              size="sm"
              :is-loading="isAddingToCrm"
              :disabled="!selectedPipelineId || !selectedStageId || isAddingToCrm"
              @click="submitAddToCrm"
            />
          </div>
        </div>
      </div>
    </Teleport>

    <div class="flex flex-col items-start gap-6">
      <ContactsForm
        ref="contactsFormRef"
        :contact-data="contactData"
        is-details-view
        @update="handleFormUpdate"
      />
      <Button
        :label="t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')"
        size="sm"
        :is-loading="isUpdating"
        :disabled="isUpdating || isFormInvalid"
        @click="updateContact"
      />
    </div>
    <Policy :permissions="['administrator']">
      <div
        class="flex flex-col items-start w-full gap-4 pt-6 border-t border-n-strong"
      >
        <div class="flex flex-col gap-2">
          <h6 class="text-base font-medium text-n-slate-12">
            {{ t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT') }}
          </h6>
          <span class="text-sm text-n-slate-11">
            {{ t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT_DESCRIPTION') }}
          </span>
        </div>
        <Button
          :label="t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT')"
          color="ruby"
          @click="openConfirmDeleteContactDialog"
        />
      </div>
      <ConfirmContactDeleteDialog
        ref="confirmDeleteContactDialogRef"
        :selected-contact="selectedContact"
        @go-to-contacts-list="emit('goToContactsList')"
      />
    </Policy>
  </div>
</template>
