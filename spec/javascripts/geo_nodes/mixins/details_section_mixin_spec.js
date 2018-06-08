import Vue from 'vue';

import DetailsSectionMixin from 'ee/geo_nodes/mixins/details_section_mixin';
import { STATUS_DELAY_THRESHOLD_MS } from 'ee/geo_nodes/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../mock_data';

const createComponent = (nodeDetails = mockNodeDetails) => {
  const Component = Vue.extend({
    template: '<div></div>',
    mixins: [DetailsSectionMixin],
    data() {
      return { nodeDetails };
    },
  });

  return mountComponent(Component);
};

describe('DetailsSectionMixin', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('statusInfoStale', () => {
      it('returns true when `nodeDetails.statusCheckTimestamp` is past the value of STATUS_DELAY_THRESHOLD_MS', () => {
        // Move statusCheckTimestamp to 2 minutes in the past
        const statusCheckTimestamp = new Date(Date.now() - STATUS_DELAY_THRESHOLD_MS * 2).getTime();
        vm = createComponent(Object.assign({}, mockNodeDetails, { statusCheckTimestamp }));

        expect(vm.statusInfoStale).toBe(true);
      });

      it('returns false when `nodeDetails.statusCheckTimestamp` is under the value of STATUS_DELAY_THRESHOLD_MS', () => {
        // Move statusCheckTimestamp to 30 seconds in the past
        const statusCheckTimestamp = new Date(Date.now() - STATUS_DELAY_THRESHOLD_MS / 2).getTime();
        vm = createComponent(Object.assign({}, mockNodeDetails, { statusCheckTimestamp }));

        expect(vm.statusInfoStale).toBe(false);
      });
    });

    describe('statusInfoStaleMessage', () => {
      it('returns stale information message containing the duration elapsed', () => {
        // Move statusCheckTimestamp to 1 minute in the past
        const statusCheckTimestamp = new Date(Date.now() - STATUS_DELAY_THRESHOLD_MS).getTime();
        vm = createComponent(Object.assign({}, mockNodeDetails, { statusCheckTimestamp }));

        expect(vm.statusInfoStaleMessage).toBe('Data is out of date from 1 minute ago');
      });
    });
  });
});
