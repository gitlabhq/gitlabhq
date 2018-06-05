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

  describe('methods', () => {
    describe('getPrimaryNodeDetailItems', () => {
      const primaryItems = [
        {
          title: 'Repository checksum progress',
          valueProp: 'repositoriesChecksummed',
        },
        {
          title: 'Wiki checksum progress',
          valueProp: 'wikisChecksummed',
        },
      ];

      it('returns array containing items to show under primary node', () => {
        const actualPrimaryItems = vm.getPrimaryNodeDetailItems();
        primaryItems.forEach((item, index) => {
          expect(actualPrimaryItems[index].itemTitle).toBe(item.title);
          expect(actualPrimaryItems[index].itemValue).toBe(mockNodeDetails[item.valueProp]);
        });
      });
    });

    describe('getSecondaryNodeDetailItems', () => {
      const secondaryItems = [
        {
          title: 'Repository verification progress',
          valueProp: 'verifiedRepositories',
        },
        {
          title: 'Wiki verification progress',
          valueProp: 'verifiedWikis',
        },
      ];

      it('returns array containing items to show under secondary node', () => {
        const actualSecondaryItems = vm.getSecondaryNodeDetailItems();
        secondaryItems.forEach((item, index) => {
          expect(actualSecondaryItems[index].itemTitle).toBe(item.title);
          expect(actualSecondaryItems[index].itemValue).toBe(mockNodeDetails[item.valueProp]);
        });
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
