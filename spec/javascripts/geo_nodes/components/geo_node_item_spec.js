import Vue from 'vue';

import geoNodeItemComponent from 'ee/geo_nodes/components/geo_node_item.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodes, mockNodeDetails } from '../mock_data';

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
      expect(vm.isNodeDetailsFailed).toBeFalsy();
      expect(vm.nodeHealthStatus).toBe('');
      expect(vm.errorMessage).toBe('');
      expect(typeof vm.nodeDetails).toBe('object');
    });
  });

  describe('computed', () => {
    let vmHttps;
    let mockNode;

    beforeEach(() => {
      // Altered mock data for secure URL
      mockNode = Object.assign({}, mockNodes[0], {
        url: 'https://127.0.0.1:3001/',
      });
      vmHttps = createComponent(mockNode);
    });

    afterEach(() => {
      vmHttps.$destroy();
    });

    describe('isNodeNonHTTPS', () => {
      it('returns `true` if Node URL protocol is non-HTTPS', () => {
        // With default mock data
        expect(vm.isNodeNonHTTPS).toBeTruthy();
      });

      it('returns `false` is Node URL protocol is HTTPS', () => {
        // With altered mock data
        expect(vmHttps.isNodeNonHTTPS).toBeFalsy();
      });
    });

    describe('showNodeStatusIcon', () => {
      it('returns `false` if Node details are still loading', () => {
        vm.isNodeDetailsLoading = true;
        expect(vm.showNodeStatusIcon).toBeFalsy();
      });

      it('returns `true` if Node details failed to load', () => {
        vm.isNodeDetailsLoading = false;
        vm.isNodeDetailsFailed = true;
        expect(vm.showNodeStatusIcon).toBeTruthy();
      });

      it('returns `true` if Node details loaded and Node URL is non-HTTPS', () => {
        vm.isNodeDetailsLoading = false;
        vm.isNodeDetailsFailed = false;
        expect(vm.showNodeStatusIcon).toBeTruthy();
      });

      it('returns `false` if Node details loaded and Node URL is HTTPS', () => {
        vmHttps.isNodeDetailsLoading = false;
        vmHttps.isNodeDetailsFailed = false;
        expect(vmHttps.showNodeStatusIcon).toBeFalsy();
      });
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

    describe('nodeStatusIconClass', () => {
      it('returns `node-status-icon-failure` along with default classes if Node details failed to load', () => {
        vm.isNodeDetailsFailed = true;
        expect(vm.nodeStatusIconClass).toBe('prepend-left-10 pull-left node-status-icon-failure');
      });

      it('returns `node-status-icon-warning` along with default classes if Node details loaded and Node URL is non-HTTPS', () => {
        vm.isNodeDetailsFailed = false;
        expect(vm.nodeStatusIconClass).toBe('prepend-left-10 pull-left node-status-icon-warning');
      });
    });

    describe('nodeStatusIconName', () => {
      it('returns `warning` if Node details loaded and Node URL is non-HTTPS', () => {
        vm.isNodeDetailsFailed = false;
        expect(vm.nodeStatusIconName).toBe('warning');
      });

      it('returns `status_failed_borderless` if Node details failed to load', () => {
        vm.isNodeDetailsFailed = true;
        expect(vm.nodeStatusIconName).toBe('status_failed_borderless');
      });
    });

    describe('nodeStatusIconTooltip', () => {
      it('returns empty string if Node details failed to load', () => {
        vm.isNodeDetailsFailed = true;
        expect(vm.nodeStatusIconTooltip).toBe('');
      });

      it('returns tooltip string if Node details loaded and Node URL is non-HTTPS', () => {
        vm.isNodeDetailsFailed = false;
        expect(vm.nodeStatusIconTooltip).toBe('You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.');
      });
    });
  });

  describe('methods', () => {
    describe('handleNodeDetails', () => {
      it('intializes props based on provided `nodeDetails`', () => {
        // With altered mock data with matching ID
        const mockNode = Object.assign({}, mockNodes[1]);
        const vmNodePrimary = createComponent(mockNode);

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
