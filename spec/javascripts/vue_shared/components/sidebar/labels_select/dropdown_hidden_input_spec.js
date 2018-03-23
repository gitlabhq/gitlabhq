import Vue from 'vue';

import dropdownHiddenInputComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_hidden_input.vue';

import { mockLabels } from './mock_data';

import mountComponent from '../../../../helpers/vue_mount_component_helper';

const createComponent = (name = 'label_id[]', label = mockLabels[0]) => {
  const Component = Vue.extend(dropdownHiddenInputComponent);

  return mountComponent(Component, {
    name,
    label,
  });
};

describe('DropdownHiddenInputComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders input element of type `hidden`', () => {
      expect(vm.$el.nodeName).toBe('INPUT');
      expect(vm.$el.getAttribute('type')).toBe('hidden');
      expect(vm.$el.getAttribute('name')).toBe(vm.name);
      expect(vm.$el.getAttribute('value')).toBe(`${vm.label.id}`);
    });
  });
});
