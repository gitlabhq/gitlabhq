import Vue from 'vue';

import dropdownHeaderComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_header.vue';

import mountComponent from '../../../../helpers/vue_mount_component_helper';

const createComponent = () => {
  const Component = Vue.extend(dropdownHeaderComponent);

  return mountComponent(Component);
};

describe('DropdownHeaderComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders header text element', () => {
      const headerEl = vm.$el.querySelector('.dropdown-title span');
      expect(headerEl.innerText.trim()).toBe('Assign labels');
    });

    it('renders `Close` button element', () => {
      const closeBtnEl = vm.$el.querySelector('.dropdown-title button.dropdown-title-button.dropdown-menu-close');
      expect(closeBtnEl).not.toBeNull();
      expect(closeBtnEl.querySelector('.fa-times.dropdown-menu-close-icon')).not.toBeNull();
    });
  });
});
