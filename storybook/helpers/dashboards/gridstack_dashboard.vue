<script>
import GridstackWrapper from '~/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';
import GridstackPanel from 'storybook_helpers/dashboards/gridstack_panel.vue';

export default {
  name: 'GridstackDashboard',
  components: {
    GridstackWrapper,
    GridstackPanel,
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
  <gridstack-wrapper v-model="dashboard" :editing="true">
    <template #panel="{ panel }">
      <gridstack-panel :title="panel.title">
        <slot></slot>
      </gridstack-panel>
    </template>
  </gridstack-wrapper>
</template>
