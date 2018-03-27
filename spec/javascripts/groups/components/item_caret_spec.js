import Vue from 'vue';

import itemCaretComponent from '~/groups/components/item_caret.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

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
      expect(vm.$el.classList.contains('folder-caret')).toBeTruthy();
      expect(vm.$el.querySelectorAll('svg').length).toBe(1);
      vm.$destroy();
    });

    it('should render caret down icon if `isGroupOpen` prop is `true`', () => {
      const vm = createComponent(true);
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('angle-down');
      vm.$destroy();
    });

    it('should render caret right icon if `isGroupOpen` prop is `false`', () => {
      const vm = createComponent();
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('angle-right');
      vm.$destroy();
    });
  });
});
