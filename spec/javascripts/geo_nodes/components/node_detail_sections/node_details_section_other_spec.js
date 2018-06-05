import Vue from 'vue';

import NodeDetailsSectionOtherComponent from 'ee/geo_nodes/components/node_detail_sections/node_details_section_other.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { mockNodeDetails } from '../../mock_data';

const createComponent = (
  nodeDetails = Object.assign({}, mockNodeDetails),
  nodeTypePrimary = false,
) => {
  const Component = Vue.extend(NodeDetailsSectionOtherComponent);

  return mountComponent(Component, {
    nodeDetails,
    nodeTypePrimary,
  });
};

describe('NodeDetailsSectionOther', () => {
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
    });
  });

  describe('computed', () => {
    describe('nodeDetailItems', () => {
      it('returns array containing items to show under primary node when prop `nodeTypePrimary` is true', () => {
        const vmNodePrimary = createComponent(mockNodeDetails, true);

        const items = vmNodePrimary.nodeDetailItems;

        expect(items.length).toBe(2);
        expect(items[0].itemTitle).toBe('Replication slots');
        expect(items[0].itemValue).toBe(mockNodeDetails.replicationSlots);
        expect(items[1].itemTitle).toBe('Replication slot WAL');
        expect(items[1].itemValue).toBe(numberToHumanSize(mockNodeDetails.replicationSlotWAL));

        vmNodePrimary.$destroy();
      });

      it('returns array containing items to show under secondary node when prop `nodeTypePrimary` is false', () => {
        const items = vm.nodeDetailItems;

        expect(items.length).toBe(1);
        expect(items[0].itemTitle).toBe('Storage config');
      });
    });

    describe('storageShardsStatus', () => {
      it('returns `Unknown` when `nodeDetails.storageShardsMatch` is null', (done) => {
        vm.nodeDetails.storageShardsMatch = null;
        Vue.nextTick()
          .then(() => {
            expect(vm.storageShardsStatus).toBe('Unknown');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `OK` when `nodeDetails.storageShardsMatch` is true', (done) => {
        vm.nodeDetails.storageShardsMatch = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.storageShardsStatus).toBe('OK');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns storage shard status string when `nodeDetails.storageShardsMatch` is false', () => {
        expect(vm.storageShardsStatus).toBe('Does not match the primary storage configuration');
      });
    });

    describe('storageShardsCssClass', () => {
      it('returns CSS class `node-detail-value-bold` when `nodeDetails.storageShardsMatch` is true', (done) => {
        vm.nodeDetails.storageShardsMatch = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.storageShardsCssClass).toBe('node-detail-value-bold');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns CSS class `node-detail-value-bold node-detail-value-error` when `nodeDetails.storageShardsMatch` is false', () => {
        expect(vm.storageShardsCssClass).toBe('node-detail-value-bold node-detail-value-error');
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('other-section')).toBe(true);
    });

    it('renders show section button element', () => {
      expect(vm.$el.querySelector('.btn-show-section')).not.toBeNull();
      expect(vm.$el.querySelector('.btn-show-section > span').innerText.trim()).toBe('Other information');
    });

    it('renders section items container element', () => {
      expect(vm.$el.querySelector('.section-items-container')).not.toBeNull();
    });
  });
});
