import Vue from 'vue';

import NodeDetailsSectionVerificationComponent from 'ee/geo_nodes/components/node_detail_sections/node_details_section_verification.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../../mock_data';

const createComponent = ({
  nodeDetails = mockNodeDetails,
  nodeTypePrimary = false,
}) => {
  const Component = Vue.extend(NodeDetailsSectionVerificationComponent);

  return mountComponent(Component, {
    nodeDetails,
    nodeTypePrimary,
  });
};

describe('NodeDetailsSectionVerification', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.showSectionItems).toBe(false);
      expect(Array.isArray(vm.primaryNodeDetailItems)).toBe(true);
      expect(Array.isArray(vm.secondaryNodeDetailItems)).toBe(true);
      expect(vm.primaryNodeDetailItems.length > 0).toBe(true);
      expect(vm.secondaryNodeDetailItems.length > 0).toBe(true);
    });
  });

  describe('computed', () => {
    describe('hasItemsToShow', () => {
      it('returns `true` when `nodeTypePrimary` prop is true', (done) => {
        vm.nodeTypePrimary = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.hasItemsToShow).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns value of `nodeDetails.repositoryVerificationEnabled` when `nodeTypePrimary` prop is false', () => {
        expect(vm.hasItemsToShow).toBe(mockNodeDetails.repositoryVerificationEnabled);
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('verification-section')).toBe(true);
    });

    it('renders section items container element', (done) => {
      vm.showSectionItems = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.section-items-container')).not.toBeNull();
        done();
      });
    });
  });
});
