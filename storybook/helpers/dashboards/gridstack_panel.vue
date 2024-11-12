<script>
import PanelsBase from '~/vue_shared/components/customizable_dashboard/panels_base.vue';

export default {
  name: 'GridstackPanel',
  components: {
    PanelsBase,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <panels-base :title="title">
    <template #body>
      <slot></slot>
    </template>
  </panels-base>
</template>
