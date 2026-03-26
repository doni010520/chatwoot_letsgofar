<script setup>
import { computed } from 'vue';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import AudioAlertTone from './AudioAlertTone.vue';
import { TASK_ALERT_EVENTS, TASK_EVENT_TYPES } from './constants';

const props = defineProps({
  label: { type: String, default: '' },
  value: { type: String, default: 'none' },
  tone: { type: String, default: 'ding' },
  isAdmin: { type: Boolean, default: false },
});

const emit = defineEmits(['update', 'update:tone']);

const alertEvents = computed(() => {
  if (props.isAdmin) {
    return TASK_ALERT_EVENTS;
  }
  // Agentes só veem "tarefa atribuída a mim"
  return TASK_ALERT_EVENTS.filter(e => e.value === TASK_EVENT_TYPES.TASK_ASSIGNED);
});

const selectedValue = computed({
  get: () => {
    if (props.value === 'none') return [];
    return props.value.split('+').filter(Boolean);
  },
  set: value => {
    const sorted = [...new Set(value.filter(Boolean).sort())];
    emit('update', sorted.length === 0 ? 'none' : sorted.join('+'));
  },
});

const setValue = (isChecked, value) => {
  let updated = [...selectedValue.value];
  if (isChecked) {
    updated.push(value);
  } else {
    updated = updated.filter(item => item !== value);
  }
  selectedValue.value = updated;
};

const handleToneChange = value => {
  emit('update:tone', value);
};
</script>

<template>
  <div>
    <label class="pb-1 text-sm font-medium leading-6 text-n-slate-12">
      {{ label }}
    </label>
    <div class="grid gap-3 mt-2">
      <div v-for="option in alertEvents" :key="option.value" class="flex items-center gap-2">
        <CheckBox
          :id="`task-checkbox-${option.value}`"
          :is-checked="selectedValue.includes(option.value)"
          @update="(_val, isChecked) => setValue(isChecked, option.value)"
        />
        <label :for="`task-checkbox-${option.value}`" class="text-sm text-n-slate-12 font-normal">
          {{ $t(`PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TASK_ALERT_TYPES.${option.label.toUpperCase()}`) }}
        </label>
      </div>
    </div>
    
    <div class="mt-4">
      <AudioAlertTone
        :value="tone"
        :label="$t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.TASK_ALERTS.TONE_LABEL')"
        @change="handleToneChange"
      />
    </div>
  </div>
</template>
