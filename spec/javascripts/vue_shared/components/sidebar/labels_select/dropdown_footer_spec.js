import Vue from 'vue';

import dropdownFooterComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_footer.vue';

import { mockConfig } from './mock_data';

import mountComponent from '../../../../helpers/vue_mount_component_helper';

const createComponent = (labelsWebUrl = mockConfig.labelsWebUrl) => {
  const Component = Vue.extend(dropdownFooterComponent);

  return mountComponent(Component, {
    labelsWebUrl,
  });
};

describe('DropdownFooterComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders `Create new label` link element', () => {
      const createLabelEl = vm.$el.querySelector('.dropdown-footer-list .dropdown-toggle-page');
      expect(createLabelEl).not.toBeNull();
      expect(createLabelEl.innerText.trim()).toBe('Create new label');
    });

    it('renders `Manage labels` link element', () => {
      const manageLabelsEl = vm.$el.querySelector('.dropdown-footer-list .dropdown-external-link');
      expect(manageLabelsEl).not.toBeNull();
      expect(manageLabelsEl.getAttribute('href')).toBe(vm.labelsWebUrl);
      expect(manageLabelsEl.innerText.trim()).toBe('Manage labels');
    });
  });
});
