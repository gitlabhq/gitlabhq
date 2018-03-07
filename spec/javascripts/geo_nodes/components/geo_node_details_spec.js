import Vue from 'vue';

import geoNodeDetailsComponent from 'ee/geo_nodes/components/geo_node_details.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodes, mockNodeDetails } from '../mock_data';

const createComponent = (nodeDetails = mockNodeDetails) => {
  const Component = Vue.extend(geoNodeDetailsComponent);

  return mountComponent(Component, {
    nodeDetails,
    node: mockNodes[1],
  });
};

describe('GeoNodeDetailsComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.showAdvanceItems).toBeFalsy();
      expect(vm.errorMessage).toBe('');
      expect(Array.isArray(vm.nodeDetailItems)).toBeTruthy();
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
        const vmX = createComponent(nodeDetails);
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
        const vmX = createComponent(nodeDetails);
        expect(vmX.errorMessage).toBe('GitLab version does not match the primary node version');
        expect(vmX.hasVersionMismatch).toBeTruthy();
        vmX.$destroy();

        // With default mock data
        expect(vm.hasVersionMismatch).toBeFalsy();
      });
    });

    describe('advanceButtonIcon', () => {
      it('returns button icon name', () => {
        vm.showAdvanceItems = true;
        expect(vm.advanceButtonIcon).toBe('angle-up');
        vm.showAdvanceItems = false;
        expect(vm.advanceButtonIcon).toBe('angle-down');
      });
    });

    describe('nodeVersion', () => {
      it('returns `Unknown` when `version` and `revision` are null', () => {
        const nodeDetailsVersionNull = Object.assign({}, mockNodeDetails, {
          version: null,
          revision: null,
        });
        const vmVersionNull = createComponent(nodeDetailsVersionNull);
        expect(vmVersionNull.nodeVersion).toBe('Unknown');
        vmVersionNull.$destroy();
      });

      it('returns version string', () => {
        expect(vm.nodeVersion).toBe('10.4.0-pre (b93c51849b)');
      });
    });

    describe('replicationSlotWAL', () => {
      it('returns replication slot WAL in Megabytes', () => {
        expect(vm.replicationSlotWAL).toBe('479.37 MiB');
      });
    });

    describe('dbReplicationLag', () => {
      it('returns DB replication lag time duration', () => {
        expect(vm.dbReplicationLag).toBe('0m');
      });

      it('returns `Unknown` when `dbReplicationLag` is null', () => {
        const nodeDetailsLagNull = Object.assign({}, mockNodeDetails, {
          dbReplicationLag: null,
        });
        const vmLagNull = createComponent(nodeDetailsLagNull);
        expect(vmLagNull.dbReplicationLag).toBe('Unknown');
        vmLagNull.$destroy();
      });
    });

    describe('lastEventStatus', () => {
      it('returns event status object', () => {
        expect(vm.lastEventStatus.eventId).toBe(mockNodeDetails.lastEvent.id);
        expect(vm.lastEventStatus.eventTimeStamp).toBe(mockNodeDetails.lastEvent.timeStamp);
      });
    });

    describe('cursorLastEventStatus', () => {
      it('returns event status object', () => {
        expect(vm.cursorLastEventStatus.eventId).toBe(mockNodeDetails.cursorLastEvent.id);
        expect(vm.cursorLastEventStatus.eventTimeStamp)
          .toBe(mockNodeDetails.cursorLastEvent.timeStamp);
      });
    });
  });

  describe('methods', () => {
    describe('nodeHealthStatus', () => {
      it('returns health status string', () => {
        // With altered mock data for Unhealthy status
        const nodeDetails = Object.assign({}, mockNodeDetails, {
          healthStatus: 'Unhealthy',
          healthy: false,
        });
        const vmX = createComponent(nodeDetails);
        expect(vmX.nodeHealthStatus()).toBe('Unhealthy');
        vmX.$destroy();

        // With default mock data
        expect(vm.nodeHealthStatus()).toBe('Healthy');
      });
    });

    describe('storageShardsStatus', () => {
      it('returns storage shard status string', () => {
        // With altered mock data for Unhealthy status
        let nodeDetails = Object.assign({}, mockNodeDetails, {
          storageShardsMatch: null,
        });
        let vmX = createComponent(nodeDetails);
        expect(vmX.storageShardsStatus()).toBe('Unknown');
        vmX.$destroy();

        nodeDetails = Object.assign({}, mockNodeDetails, {
          storageShardsMatch: true,
        });
        vmX = createComponent(nodeDetails);
        expect(vmX.storageShardsStatus()).toBe('OK');
        vmX.$destroy();

        // With default mock data
        expect(vm.storageShardsStatus()).toBe('Does not match the primary storage configuration');
      });
    });

    describe('plainValueCssClass', () => {
      it('returns CSS class for plain value item', () => {
        expect(vm.plainValueCssClass()).toBe('node-detail-value-bold');
        expect(vm.plainValueCssClass(true)).toBe('node-detail-value-bold node-detail-value-error');
      });
    });

    describe('syncSettings', () => {
      it('returns sync settings object', () => {
        const nodeDetailsUnknownSync = Object.assign({}, mockNodeDetails, {
          syncStatusUnavailable: true,
        });
        const vmUnknownSync = createComponent(nodeDetailsUnknownSync);

        const syncSettings = vmUnknownSync.syncSettings();
        expect(syncSettings.syncStatusUnavailable).toBe(true);
        expect(syncSettings.namespaces).toBe(mockNodeDetails.namespaces);
        expect(syncSettings.lastEvent).toBe(mockNodeDetails.lastEvent);
        expect(syncSettings.cursorLastEvent).toBe(mockNodeDetails.cursorLastEvent);
        vmUnknownSync.$destroy();
      });
    });

    describe('onClickShowAdvance', () => {
      it('toggles `showAdvanceItems` prop', () => {
        vm.showAdvanceItems = true;
        vm.onClickShowAdvance();
        expect(vm.showAdvanceItems).toBeFalsy();
        vm.showAdvanceItems = false;
        vm.onClickShowAdvance();
        expect(vm.showAdvanceItems).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.querySelectorAll('.node-details-list').length).not.toBe(0);
      expect(vm.$el.querySelectorAll('.btn-show-advanced').length).not.toBe(0);
    });
  });
});
