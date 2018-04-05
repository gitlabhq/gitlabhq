import Vue from 'vue';

import NodeDetailsSectionSyncComponent from 'ee/geo_nodes/components/node_detail_sections/node_details_section_sync.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../../mock_data';

const createComponent = (
  nodeDetails = Object.assign({}, mockNodeDetails),
) => {
  const Component = Vue.extend(NodeDetailsSectionSyncComponent);

  return mountComponent(Component, {
    nodeDetails,
  });
};

describe('NodeDetailsSectionSync', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.showSectionItems).toBe(false);
      expect(Array.isArray(vm.nodeDetailItems)).toBe(true);
      expect(vm.nodeDetailItems.length > 0).toBe(true);
    });
  });

  describe('methods', () => {
    describe('syncSettings', () => {
      it('returns sync settings object', (done) => {
        vm.nodeDetails.syncStatusUnavailable = true;
        Vue.nextTick()
          .then(() => {
            const syncSettings = vm.syncSettings();
            expect(syncSettings.syncStatusUnavailable).toBe(true);
            expect(syncSettings.namespaces).toBe(mockNodeDetails.namespaces);
            expect(syncSettings.lastEvent).toBe(mockNodeDetails.lastEvent);
            expect(syncSettings.cursorLastEvent).toBe(mockNodeDetails.cursorLastEvent);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('dbReplicationLag', () => {
      it('returns DB replication lag time duration', () => {
        expect(vm.dbReplicationLag()).toBe('0m');
      });

      it('returns `Unknown` when `dbReplicationLag` is null', (done) => {
        vm.nodeDetails.dbReplicationLag = null;
        Vue.nextTick()
          .then(() => {
            expect(vm.dbReplicationLag()).toBe('Unknown');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('lastEventStatus', () => {
      it('returns event status object', () => {
        expect(vm.lastEventStatus().eventId).toBe(mockNodeDetails.lastEvent.id);
        expect(vm.lastEventStatus().eventTimeStamp).toBe(mockNodeDetails.lastEvent.timeStamp);
      });
    });

    describe('cursorLastEventStatus', () => {
      it('returns event status object', () => {
        expect(vm.cursorLastEventStatus().eventId).toBe(mockNodeDetails.cursorLastEvent.id);
        expect(vm.cursorLastEventStatus().eventTimeStamp)
          .toBe(mockNodeDetails.cursorLastEvent.timeStamp);
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('sync-section')).toBe(true);
    });

    it('renders show section button element', () => {
      expect(vm.$el.querySelector('.btn-show-section')).not.toBeNull();
      expect(vm.$el.querySelector('.btn-show-section > span').innerText.trim()).toBe('Sync information');
    });

    it('renders section items container element', () => {
      expect(vm.$el.querySelector('.section-items-container')).not.toBeNull();
    });
  });
});
