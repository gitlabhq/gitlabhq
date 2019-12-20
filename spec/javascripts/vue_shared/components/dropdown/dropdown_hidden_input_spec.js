import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import dropdownHiddenInputComponent from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import { mockLabels } from './mock_data';

const createComponent = (name = 'label_id[]', value = mockLabels[0].id) => {
  const Component = Vue.extend(dropdownHiddenInputComponent);

  return mountComponent(Component, {
    name,
    value,
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
      expect(vm.$el.getAttribute('value')).toBe(`${vm.value}`);
    });
  });
});
