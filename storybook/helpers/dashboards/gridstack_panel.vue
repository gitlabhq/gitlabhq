<script>
import ExtendedDashboardPanel from '~/vue_shared/components/customizable_dashboard/extended_dashboard_panel.vue';

export default {
  name: 'GridstackPanel',
  components: {
    ExtendedDashboardPanel,
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
  <extended-dashboard-panel :title="title">
    <template #body>
      <slot></slot>
    </template>
  </extended-dashboard-panel>
</template>
