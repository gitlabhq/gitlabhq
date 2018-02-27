import Vue from 'vue';

import itemStatsComponent from '~/groups/components/item_stats.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  mockParentGroupItem,
  ITEM_TYPE,
  VISIBILITY_TYPE_ICON,
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
} from '../mock_data';

const createComponent = (item = mockParentGroupItem) => {
  const Component = Vue.extend(itemStatsComponent);

  return mountComponent(Component, {
    item,
  });
};

describe('ItemStatsComponent', () => {
  describe('computed', () => {
    describe('visibilityIcon', () => {
      it('should return icon class based on `item.visibility` value', () => {
        Object.keys(VISIBILITY_TYPE_ICON).forEach((visibility) => {
          const item = Object.assign({}, mockParentGroupItem, { visibility });
          const vm = createComponent(item);
          expect(vm.visibilityIcon).toBe(VISIBILITY_TYPE_ICON[visibility]);
          vm.$destroy();
        });
      });
    });

    describe('visibilityTooltip', () => {
      it('should return tooltip string for Group based on `item.visibility` value', () => {
        Object.keys(GROUP_VISIBILITY_TYPE).forEach((visibility) => {
          const item = Object.assign({}, mockParentGroupItem, {
            visibility,
            type: ITEM_TYPE.GROUP,
          });
          const vm = createComponent(item);
          expect(vm.visibilityTooltip).toBe(GROUP_VISIBILITY_TYPE[visibility]);
          vm.$destroy();
        });
      });

      it('should return tooltip string for Project based on `item.visibility` value', () => {
        Object.keys(PROJECT_VISIBILITY_TYPE).forEach((visibility) => {
          const item = Object.assign({}, mockParentGroupItem, {
            visibility,
            type: ITEM_TYPE.PROJECT,
          });
          const vm = createComponent(item);
          expect(vm.visibilityTooltip).toBe(PROJECT_VISIBILITY_TYPE[visibility]);
          vm.$destroy();
        });
      });
    });

    describe('isProject', () => {
      it('should return boolean value representing whether `item.type` is Project or not', () => {
        let item;
        let vm;

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.PROJECT });
        vm = createComponent(item);
        expect(vm.isProject).toBeTruthy();
        vm.$destroy();

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.GROUP });
        vm = createComponent(item);
        expect(vm.isProject).toBeFalsy();
        vm.$destroy();
      });
    });

    describe('isGroup', () => {
      it('should return boolean value representing whether `item.type` is Group or not', () => {
        let item;
        let vm;

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.GROUP });
        vm = createComponent(item);
        expect(vm.isGroup).toBeTruthy();
        vm.$destroy();

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.PROJECT });
        vm = createComponent(item);
        expect(vm.isGroup).toBeFalsy();
        vm.$destroy();
      });
    });
  });

  describe('template', () => {
    it('renders component container element correctly', () => {
      const vm = createComponent();

      expect(vm.$el.classList.contains('stats')).toBeTruthy();

      vm.$destroy();
    });

    it('renders item visibility icon and tooltip correctly', () => {
      const vm = createComponent();

      const visibilityIconEl = vm.$el.querySelector('.item-visibility');
      expect(visibilityIconEl).not.toBe(null);
      expect(visibilityIconEl.dataset.originalTitle).toBe(vm.visibilityTooltip);
      expect(visibilityIconEl.querySelectorAll('svg').length > 0).toBeTruthy();

      vm.$destroy();
    });

    it('renders start count and last updated information for project item correctly', () => {
      const item = Object.assign({}, mockParentGroupItem, {
        type: ITEM_TYPE.PROJECT,
        starCount: 4,
      });
      const vm = createComponent(item);

      const projectStarIconEl = vm.$el.querySelector('.project-stars');
      expect(projectStarIconEl).not.toBe(null);
      expect(projectStarIconEl.querySelectorAll('svg').length > 0).toBeTruthy();
      expect(projectStarIconEl.querySelectorAll('.stat-value').length > 0).toBeTruthy();
      expect(vm.$el.querySelectorAll('.last-updated').length > 0).toBeTruthy();

      vm.$destroy();
    });
  });
});
