import Vue from 'vue';

import geoNodeActionsComponent from 'ee/geo_nodes/components/geo_node_actions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodes } from '../mock_data';

const createComponent = (node = mockNodes[0], nodeEditAllowed = true, nodeMissingOauth = false) => {
  const Component = Vue.extend(geoNodeActionsComponent);

  return mountComponent(Component, {
    node,
    nodeEditAllowed,
    nodeMissingOauth,
  });
};

describe('GeoNodeActionsComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      const vmX = createComponent();
      expect(vmX.isNodeToggleInProgress).toBeFalsy();
      vmX.$destroy();
    });
  });

  describe('computed', () => {
    describe('isToggleAllowed', () => {
      it('returns boolean value representing if toggle on node can be allowed', () => {
        let vmX = createComponent(mockNodes[0], true, false);
        expect(vmX.isToggleAllowed).toBeFalsy();
        vmX.$destroy();

        vmX = createComponent(mockNodes[1]);
        expect(vmX.isToggleAllowed).toBeTruthy();
        vmX.$destroy();
      });
    });

    describe('nodeToggleLabel', () => {
      it('returns label for toggle button for a node', () => {
        let mockNode = Object.assign({}, mockNodes[1]);
        let vmX = createComponent(mockNode);
        expect(vmX.nodeToggleLabel).toBe('Disable');
        vmX.$destroy();

        mockNode = Object.assign({}, mockNodes[1], { enabled: false });
        vmX = createComponent(mockNode);
        expect(vmX.nodeToggleLabel).toBe('Enable');
        vmX.$destroy();
      });
    });

    describe('nodeDisableMessage', () => {
      it('returns node toggle message', () => {
        let mockNode = Object.assign({}, mockNodes[1]);
        let vmX = createComponent(mockNode);
        expect(vmX.nodeDisableMessage).toBe('Disabling a node stops the sync process. Are you sure?');
        vmX.$destroy();

        mockNode = Object.assign({}, mockNodes[1], { enabled: false });
        vmX = createComponent(mockNode);
        expect(vmX.nodeDisableMessage).toBe('');
        vmX.$destroy();
      });
    });

    describe('nodePath', () => {
      it('returns node path', () => {
        expect(vm.nodePath).toBe('/admin/geo_nodes/1');
      });
    });

    describe('nodeRepairAuthPath', () => {
      it('returns node repair authentication path', () => {
        expect(vm.nodeRepairAuthPath).toBe('/admin/geo_nodes/1/repair');
      });
    });

    describe('nodeTogglePath', () => {
      it('returns node toggle path', () => {
        expect(vm.nodeTogglePath).toBe('/admin/geo_nodes/1/toggle');
      });
    });

    describe('nodeEditPath', () => {
      it('returns node edit path', () => {
        expect(vm.nodeEditPath).toBe('/admin/geo_nodes/1/edit');
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('geo-node-actions')).toBeTruthy();
      expect(vm.$el.querySelectorAll('.node-action-container').length).not.toBe(0);
      expect(vm.$el.querySelectorAll('.btn-node-action').length).not.toBe(0);
    });
  });
});
