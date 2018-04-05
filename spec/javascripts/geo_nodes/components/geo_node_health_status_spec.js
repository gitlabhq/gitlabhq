import Vue from 'vue';

import geoNodeHealthStatusComponent from 'ee/geo_nodes/components/geo_node_health_status.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../mock_data';

const createComponent = (status = mockNodeDetails.health) => {
  const Component = Vue.extend(geoNodeHealthStatusComponent);

  return mountComponent(Component, {
    status,
  });
};

describe('GeoNodeHealthStatusComponent', () => {
  describe('computed', () => {
    describe('healthCssClass', () => {
      it('returns CSS class representing `status` prop value', () => {
        const vm = createComponent('Healthy');
        expect(vm.healthCssClass).toBe('geo-node-healthy');
        vm.$destroy();
      });
    });

    describe('statusIconName', () => {
      it('returns icon name representing `status` prop value', () => {
        let vm = createComponent('Healthy');
        expect(vm.statusIconName).toBe('status_success');
        vm.$destroy();

        vm = createComponent('Unhealthy');
        expect(vm.statusIconName).toBe('status_failed');
        vm.$destroy();

        vm = createComponent('Disabled');
        expect(vm.statusIconName).toBe('status_canceled');
        vm.$destroy();

        vm = createComponent('Unknown');
        expect(vm.statusIconName).toBe('status_warning');
        vm.$destroy();

        vm = createComponent('Offline');
        expect(vm.statusIconName).toBe('status_canceled');
        vm.$destroy();
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      const vm = createComponent('Healthy');
      expect(vm.$el.classList.contains('detail-section-item')).toBe(true);
      expect(vm.$el.querySelector('.node-detail-title').innerText.trim()).toBe('Health status:');

      const iconContainerEl = vm.$el.querySelector('.node-detail-value.node-health-status');
      expect(iconContainerEl).not.toBeNull();
      expect(iconContainerEl.querySelector('svg use').getAttribute('xlink:href')).toContain('#status_success');
      expect(iconContainerEl.querySelector('.status-text').innerText.trim()).toBe('Healthy');
      vm.$destroy();
    });
  });
});
