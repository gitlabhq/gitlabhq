<script>
import { GlDashboardLayout } from '@gitlab/ui';
import ExtendedDashboardPanel from '~/vue_shared/components/customizable_dashboard/extended_dashboard_panel.vue';

export default {
  name: 'DashboardLayout',
  components: {
    GlDashboardLayout,
    ExtendedDashboardPanel,
  },

  props: {
    panels: {
      type: Array,
      required: true,
    },
  },
  computed: {
    dashboard() {
      return {
        panels: this.panels,
      };
    },
  },
};
</script>
<template>
  <gl-dashboard-layout :config="dashboard">
    <template #panel="{ panel }">
      <extended-dashboard-panel :title="panel.title">
        <template #body>
          <slot></slot>
        </template>
      </extended-dashboard-panel>
    </template>
  </gl-dashboard-layout>
</template>
