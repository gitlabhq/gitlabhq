import Vue from 'vue';

import itemCaretComponent from '~/groups/components/item_caret.vue';

import mountComponent from '../../helpers/vue_mount_component_helper';

const createComponent = (isGroupOpen = false) => {
  const Component = Vue.extend(itemCaretComponent);

  return mountComponent(Component, {
    isGroupOpen,
  });
};

describe('ItemCaretComponent', () => {
  describe('template', () => {
    it('should render component template correctly', () => {
      const vm = createComponent();
      vm.$mount();
      expect(vm.$el.classList.contains('folder-caret')).toBeTruthy();
      vm.$destroy();
    });

    it('should render caret down icon if `isGroupOpen` prop is `true`', () => {
      const vm = createComponent(true);
      vm.$mount();
      expect(vm.$el.querySelectorAll('i.fa.fa-caret-down').length).toBe(1);
      expect(vm.$el.querySelectorAll('i.fa.fa-caret-right').length).toBe(0);
      vm.$destroy();
    });

    it('should render caret right icon if `isGroupOpen` prop is `false`', () => {
      const vm = createComponent();
      vm.$mount();
      expect(vm.$el.querySelectorAll('i.fa.fa-caret-down').length).toBe(0);
      expect(vm.$el.querySelectorAll('i.fa.fa-caret-right').length).toBe(1);
      vm.$destroy();
    });
  });
});
