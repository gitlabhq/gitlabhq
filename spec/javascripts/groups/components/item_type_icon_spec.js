import Vue from 'vue';

import itemTypeIconComponent from '~/groups/components/item_type_icon.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { ITEM_TYPE } from '../mock_data';

const createComponent = (itemType = ITEM_TYPE.GROUP, isGroupOpen = false) => {
  const Component = Vue.extend(itemTypeIconComponent);

  return mountComponent(Component, {
    itemType,
    isGroupOpen,
  });
};

describe('ItemTypeIconComponent', () => {
  describe('template', () => {
    it('should render component template correctly', () => {
      const vm = createComponent();
      vm.$mount();
      expect(vm.$el.classList.contains('item-type-icon')).toBeTruthy();
      vm.$destroy();
    });

    it('should render folder open or close icon based `isGroupOpen` prop value', () => {
      let vm;

      vm = createComponent(ITEM_TYPE.GROUP, true);
      vm.$mount();
      expect(vm.$el.querySelector('use').getAttribute('xlink:href')).toContain('folder-open');
      vm.$destroy();

      vm = createComponent(ITEM_TYPE.GROUP);
      vm.$mount();
      expect(vm.$el.querySelector('use').getAttribute('xlink:href')).toContain('folder');
      vm.$destroy();
    });

    it('should render bookmark icon based on `isProject` prop value', () => {
      let vm;

      vm = createComponent(ITEM_TYPE.PROJECT);
      vm.$mount();
      expect(vm.$el.querySelector('use').getAttribute('xlink:href')).toContain('bookmark');
      vm.$destroy();

      vm = createComponent(ITEM_TYPE.GROUP);
      vm.$mount();
      expect(vm.$el.querySelector('use').getAttribute('xlink:href')).not.toContain('bookmark');
      vm.$destroy();
    });
  });
});
