import Vue from 'vue';

import geoNodeItemComponent from 'ee/geo_nodes/components/geo_node_item.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import { mockNodes, mockNodeDetails } from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

const createComponent = (node = mockNodes[0]) => {
  const Component = Vue.extend(geoNodeItemComponent);

  return mountComponent(Component, {
    node,
    primaryNode: true,
    nodeActionsAllowed: true,
    nodeEditAllowed: true,
  });
};

describe('GeoNodeItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.isNodeDetailsLoading).toBeTruthy();
      expect(vm.nodeHealthStatus).toBe('');
      expect(typeof vm.nodeDetails).toBe('object');
    });
  });

  describe('computed', () => {
    describe('showInsecureUrlWarning', () => {
      it('returns boolean value representing URL protocol security', () => {
        // With altered mock data for secure URL
        const mockNode = Object.assign({}, mockNodes[0], {
          url: 'https://127.0.0.1:3001/',
        });
        const vmX = createComponent(mockNode);
        expect(vmX.showInsecureUrlWarning).toBeFalsy();
        vmX.$destroy();

        // With default mock data
        expect(vm.showInsecureUrlWarning).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('handleNodeDetails', () => {
      it('intializes props based on provided `nodeDetails`', () => {
        // With altered mock data with matching ID
        const mockNode = Object.assign({}, mockNodes[1]);
        const vmX = createComponent(mockNode);

        vmX.handleNodeDetails(mockNodeDetails);
        expect(vmX.isNodeDetailsLoading).toBeFalsy();
        expect(vmX.nodeDetails).toBe(mockNodeDetails);
        expect(vmX.nodeHealthStatus).toBe(mockNodeDetails.health);
        vmX.$destroy();

        // With default mock data without matching ID
        vm.handleNodeDetails(mockNodeDetails);
        expect(vm.isNodeDetailsLoading).toBeTruthy();
        expect(vm.nodeDetails).not.toBe(mockNodeDetails);
        expect(vm.nodeHealthStatus).not.toBe(mockNodeDetails.health);
      });
    });

    describe('handleMounted', () => {
      it('emits `pollNodeDetails` event and passes node ID', () => {
        spyOn(eventHub, '$emit');

        vm.handleMounted();
        expect(eventHub.$emit).toHaveBeenCalledWith('pollNodeDetails', mockNodes[0].id);
      });
    });
  });

  describe('created', () => {
    it('binds `nodeDetailsLoaded` event handler', () => {
      spyOn(eventHub, '$on');

      const vmX = createComponent();
      expect(eventHub.$on).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `nodeDetailsLoaded` event handler', () => {
      spyOn(eventHub, '$off');

      const vmX = createComponent();
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders node URL', () => {
      expect(vm.$el.querySelectorAll('.node-url').length).not.toBe(0);
    });

    it('renders node details loading animation', () => {
      vm.isNodeDetailsLoading = true;
      expect(vm.$el.querySelectorAll('.node-details-loading').length).not.toBe(0);
    });

    it('renders node badge `Current node`', () => {
      expect(vm.$el.querySelectorAll('.node-badge.current-node').length).not.toBe(0);
    });

    it('renders node badge `Primary`', () => {
      expect(vm.$el.querySelectorAll('.node-badge.primary-node').length).not.toBe(0);
    });
  });
});
