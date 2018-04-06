import Vue from 'vue';

import geoNodeItemComponent from 'ee/geo_nodes/components/geo_node_item.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNode, mockNodeDetails } from '../mock_data';

const createComponent = (node = mockNode) => {
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
      expect(vm.isNodeDetailsLoading).toBe(true);
      expect(vm.isNodeDetailsFailed).toBe(false);
      expect(vm.nodeHealthStatus).toBe('');
      expect(vm.errorMessage).toBe('');
      expect(typeof vm.nodeDetails).toBe('object');
    });
  });

  describe('computed', () => {
    let vmHttps;
    let httpsNode;

    beforeEach(() => {
      // Altered mock data for secure URL
      httpsNode = Object.assign({}, mockNode, {
        url: 'https://127.0.0.1:3001/',
      });
      vmHttps = createComponent(httpsNode);
    });

    afterEach(() => {
      vmHttps.$destroy();
    });

    describe('showNodeDetails', () => {
      it('returns `false` if Node details are still loading', () => {
        vm.isNodeDetailsLoading = true;
        expect(vm.showNodeDetails).toBeFalsy();
      });

      it('returns `false` if Node details failed to load', () => {
        vm.isNodeDetailsLoading = false;
        vm.isNodeDetailsFailed = true;
        expect(vm.showNodeDetails).toBeFalsy();
      });

      it('returns `true` if Node details loaded', () => {
        vm.isNodeDetailsLoading = false;
        vm.isNodeDetailsFailed = false;
        expect(vm.showNodeDetails).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('handleNodeDetails', () => {
      it('intializes props based on provided `nodeDetails`', () => {
        // With altered mock data with matching ID
        const mockNodeSecondary = Object.assign({}, mockNode, {
          id: mockNodeDetails.id,
          primary: false,
        });
        const vmNodePrimary = createComponent(mockNodeSecondary);

        vmNodePrimary.handleNodeDetails(mockNodeDetails);
        expect(vmNodePrimary.isNodeDetailsLoading).toBeFalsy();
        expect(vmNodePrimary.isNodeDetailsFailed).toBeFalsy();
        expect(vmNodePrimary.errorMessage).toBe('');
        expect(vmNodePrimary.nodeDetails).toBe(mockNodeDetails);
        expect(vmNodePrimary.nodeHealthStatus).toBe(mockNodeDetails.health);
        vmNodePrimary.$destroy();

        // With default mock data without matching ID
        vm.handleNodeDetails(mockNodeDetails);
        expect(vm.isNodeDetailsLoading).toBeTruthy();
        expect(vm.nodeDetails).not.toBe(mockNodeDetails);
        expect(vm.nodeHealthStatus).not.toBe(mockNodeDetails.health);
      });
    });

    describe('handleNodeDetailsFailure', () => {
      it('initializes props for Node details failure', () => {
        const err = 'Something went wrong';
        vm.handleNodeDetailsFailure(1, { message: err });
        expect(vm.isNodeDetailsLoading).toBeFalsy();
        expect(vm.isNodeDetailsFailed).toBeTruthy();
        expect(vm.errorMessage).toBe(err);
      });
    });

    describe('handleMounted', () => {
      it('emits `pollNodeDetails` event and passes node ID', () => {
        spyOn(eventHub, '$emit');

        vm.handleMounted();
        expect(eventHub.$emit).toHaveBeenCalledWith('pollNodeDetails', vm.node);
      });
    });
  });

  describe('created', () => {
    it('binds `nodeDetailsLoaded` event handler', () => {
      spyOn(eventHub, '$on');

      const vmX = createComponent();
      expect(eventHub.$on).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('nodeDetailsLoadFailed', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `nodeDetailsLoaded` event handler', () => {
      spyOn(eventHub, '$off');

      const vmX = createComponent();
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('nodeDetailsLoadFailed', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders container element', () => {
      expect(vm.$el.classList.contains('panel', 'panel-default', 'geo-node-item')).toBe(true);
    });

    it('renders node error message', (done) => {
      const err = 'Something error message';
      vm.isNodeDetailsFailed = true;
      vm.errorMessage = err;
      Vue.nextTick(() => {
        expect(vm.$el.querySelectorAll('p.health-message').length).not.toBe(0);
        expect(vm.$el.querySelector('p.health-message').innerText.trim()).toBe(err);
        done();
      });
    });
  });
});
