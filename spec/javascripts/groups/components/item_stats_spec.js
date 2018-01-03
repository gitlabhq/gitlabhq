import Vue from 'vue';

import itemStatsComponent from '~/groups/components/item_stats.vue';
import {
  mockParentGroupItem,
  ITEM_TYPE,
  VISIBILITY_TYPE_ICON,
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
} from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

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
          vm.$mount();
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
          vm.$mount();
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
          vm.$mount();
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
        vm.$mount();
        expect(vm.isProject).toBeTruthy();
        vm.$destroy();

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.GROUP });
        vm = createComponent(item);
        vm.$mount();
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
        vm.$mount();
        expect(vm.isGroup).toBeTruthy();
        vm.$destroy();

        item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.PROJECT });
        vm = createComponent(item);
        vm.$mount();
        expect(vm.isGroup).toBeFalsy();
        vm.$destroy();
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', () => {
      const vm = createComponent();
      vm.$mount();

      const visibilityIconEl = vm.$el.querySelector('.item-visibility');
      expect(vm.$el.classList.contains('.stats')).toBeDefined();
      expect(visibilityIconEl).toBeDefined();
      expect(visibilityIconEl.dataset.originalTitle).toBe(vm.visibilityTooltip);
      expect(visibilityIconEl.querySelector('i.fa')).toBeDefined();

      vm.$destroy();
    });

    it('should render stat icons if `item.type` is Group', () => {
      const item = Object.assign({}, mockParentGroupItem, { type: ITEM_TYPE.GROUP });
      const vm = createComponent(item);
      vm.$mount();

      const subgroupIconEl = vm.$el.querySelector('span.number-subgroups');
      expect(subgroupIconEl).toBeDefined();
      expect(subgroupIconEl.dataset.originalTitle).toBe('Subgroups');
      expect(subgroupIconEl.querySelector('i.fa.fa-folder')).toBeDefined();
      expect(subgroupIconEl.innerText.trim()).toBe(`${vm.item.subgroupCount}`);

      const projectsIconEl = vm.$el.querySelector('span.number-projects');
      expect(projectsIconEl).toBeDefined();
      expect(projectsIconEl.dataset.originalTitle).toBe('Projects');
      expect(projectsIconEl.querySelector('i.fa.fa-bookmark')).toBeDefined();
      expect(projectsIconEl.innerText.trim()).toBe(`${vm.item.projectCount}`);

      const membersIconEl = vm.$el.querySelector('span.number-users');
      expect(membersIconEl).toBeDefined();
      expect(membersIconEl.dataset.originalTitle).toBe('Members');
      expect(membersIconEl.querySelector('i.fa.fa-users')).toBeDefined();
      expect(membersIconEl.innerText.trim()).toBe(`${vm.item.memberCount}`);

      vm.$destroy();
    });

    it('should render stat icons if `item.type` is Project', () => {
      const item = Object.assign({}, mockParentGroupItem, {
        type: ITEM_TYPE.PROJECT,
        starCount: 4,
      });
      const vm = createComponent(item);
      vm.$mount();

      const projectStarIconEl = vm.$el.querySelector('.project-stars');
      expect(projectStarIconEl).toBeDefined();
      expect(projectStarIconEl.querySelector('i.fa.fa-star')).toBeDefined();
      expect(projectStarIconEl.innerText.trim()).toBe(`${vm.item.starCount}`);

      vm.$destroy();
    });
  });
});
