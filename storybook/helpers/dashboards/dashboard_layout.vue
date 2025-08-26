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
    title: {
      type: String,
      required: false,
      default: 'Dashboard Example',
    },
    panels: {
      type: Array,
      required: true,
    },
  },
  computed: {
    dashboard() {
      return {
        title: this.title,
        panels: this.panels,
      };
    },
    hasTitle() {
      return Boolean(this.dashboard.title);
    },
  },
};
</script>
<template>
  <gl-dashboard-layout :config="dashboard">
    <template v-if="!hasTitle" #title><h2 aria-hidden="true"></h2></template>
    <template #panel="{ panel }">
      <extended-dashboard-panel :title="panel.title">
        <template #body>
          <slot></slot>
        </template>
      </extended-dashboard-panel>
    </template>
  </gl-dashboard-layout>
</template>
