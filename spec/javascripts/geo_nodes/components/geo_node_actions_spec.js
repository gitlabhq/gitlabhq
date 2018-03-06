import Vue from 'vue';

import geoNodeActionsComponent from 'ee/geo_nodes/components/geo_node_actions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import eventHub from 'ee/geo_nodes/event_hub';
import { NODE_ACTIONS } from 'ee/geo_nodes/constants';
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
  });

  describe('methods', () => {
    describe('onToggleNode', () => {
      it('emits showNodeActionModal with actionType `toggle`, node reference, modalMessage and modalActionLabel', () => {
        spyOn(eventHub, '$emit');
        vm.onToggleNode();
        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.TOGGLE,
          node: vm.node,
          modalMessage: 'Disabling a node stops the sync process. Are you sure?',
          modalActionLabel: vm.nodeToggleLabel,
        });
      });
    });

    describe('onRemoveNode', () => {
      it('emits showNodeActionModal with actionType `remove`, node reference, modalKind, modalMessage and modalActionLabel', () => {
        spyOn(eventHub, '$emit');
        vm.onRemoveNode();
        expect(eventHub.$emit).toHaveBeenCalledWith('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: vm.node,
          modalKind: 'danger',
          modalMessage: 'Removing a node stops the sync process. Are you sure?',
          modalActionLabel: 'Remove',
        });
      });
    });

    describe('onRepairNode', () => {
      it('emits `repairNode` event with node reference', () => {
        spyOn(eventHub, '$emit');
        vm.onRepairNode();
        expect(eventHub.$emit).toHaveBeenCalledWith('repairNode', vm.node);
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('geo-node-actions')).toBe(true);
      expect(vm.$el.querySelectorAll('.node-action-container').length).not.toBe(0);
      expect(vm.$el.querySelectorAll('.btn-node-action').length).not.toBe(0);
    });
  });
});
