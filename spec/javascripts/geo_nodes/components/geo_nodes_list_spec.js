import Vue from 'vue';

import geoNodesListComponent from 'ee/geo_nodes/components/geo_nodes_list.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodes } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(geoNodesListComponent);

  return mountComponent(Component, {
    nodes: mockNodes,
    nodeActionsAllowed: true,
    nodeEditAllowed: true,
  });
};

describe('GeoNodesListComponent', () => {
  describe('template', () => {
    it('renders container element correctly', () => {
      const vm = createComponent();
      expect(vm.$el.classList.contains('panel', 'panel-default')).toBe(true);
      vm.$destroy();
    });
  });
});
