import Vue from 'vue';

import dropdownTitleComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_title.vue';

import mountComponent from '../../../../helpers/vue_mount_component_helper';

const createComponent = (canEdit = true) => {
  const Component = Vue.extend(dropdownTitleComponent);

  return mountComponent(Component, {
    canEdit,
  });
};

describe('DropdownTitleComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders title text', () => {
      expect(vm.$el.classList.contains('title', 'hide-collapsed')).toBe(true);
      expect(vm.$el.innerText.trim()).toContain('Labels');
    });

    it('renders spinner icon element', () => {
      expect(vm.$el.querySelector('.fa-spinner.fa-spin.block-loading')).not.toBeNull();
    });

    it('renders `Edit` button element', () => {
      const editBtnEl = vm.$el.querySelector('button.edit-link.js-sidebar-dropdown-toggle');
      expect(editBtnEl).not.toBeNull();
      expect(editBtnEl.innerText.trim()).toBe('Edit');
    });
  });
});
