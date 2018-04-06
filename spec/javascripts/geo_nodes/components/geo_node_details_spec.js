import Vue from 'vue';

import geoNodeDetailsComponent from 'ee/geo_nodes/components/geo_node_details.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNode, mockNodeDetails } from '../mock_data';

const createComponent = ({
  node = mockNode,
  nodeDetails = mockNodeDetails,
  nodeActionsAllowed = true,
  nodeEditAllowed = true,
}) => {
  const Component = Vue.extend(geoNodeDetailsComponent);

  return mountComponent(Component, {
    node,
    nodeDetails,
    nodeActionsAllowed,
    nodeEditAllowed,
  });
};

describe('GeoNodeDetailsComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.showAdvanceItems).toBeFalsy();
      expect(vm.errorMessage).toBe('');
    });
  });

  describe('computed', () => {
    describe('hasError', () => {
      it('returns boolean value representing if node has any errors', () => {
        // With altered mock data for Unhealthy status
        const nodeDetails = Object.assign({}, mockNodeDetails, {
          health: 'Something went wrong.',
          healthy: false,
        });
        const vmX = createComponent({ nodeDetails });
        expect(vmX.errorMessage).toBe('Something went wrong.');
        expect(vmX.hasError).toBeTruthy();
        vmX.$destroy();

        // With default mock data
        expect(vm.hasError).toBeFalsy();
      });
    });

    describe('hasVersionMismatch', () => {
      it('returns boolean value representing if node has version mismatch', () => {
        // With altered mock data for version mismatch
        const nodeDetails = Object.assign({}, mockNodeDetails, {
          primaryVersion: '10.3.0-pre',
          primaryRevision: 'b93c51850b',
        });
        const vmX = createComponent({ nodeDetails });
        expect(vmX.errorMessage).toBe('GitLab version does not match the primary node version');
        expect(vmX.hasVersionMismatch).toBeTruthy();
        vmX.$destroy();

        // With default mock data
        expect(vm.hasVersionMismatch).toBeFalsy();
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('panel-body')).toBe(true);
    });
  });
});
