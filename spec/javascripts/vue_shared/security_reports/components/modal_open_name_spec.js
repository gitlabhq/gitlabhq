import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal_open_name.vue';
import store from 'ee/vue_shared/security_reports/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { parsedDast } from '../mock_data';

describe('Modal open name', () => {
  const Component = Vue.extend(component);
  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(Component, {
      store,
      props: {
        issue: parsedDast[0],
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the issue name', () => {
    expect(vm.$el.textContent.trim()).toEqual(parsedDast[0].name);
  });

  it('calls openModal actions when button is clicked', () => {
    spyOn(vm, 'openModal');

    vm.$el.click();

    expect(vm.openModal).toHaveBeenCalled();
  });
});
