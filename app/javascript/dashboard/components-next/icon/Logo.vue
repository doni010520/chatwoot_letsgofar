<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import logoImage from 'dashboard/assets/images/letsgofar-logo.png';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <img
    v-else
    v-bind="attrs"
    :src="logoImage"
    alt="Let's Go Far"
  />
</template>
