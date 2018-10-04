import Vue from 'vue';
import component from '~/reports/components/modal.vue';
import state from '~/reports/store/state';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { trimText } from '../../helpers/vue_component_helper';

describe('Grouped Test Reports Modal', () => {
  const Component = Vue.extend(component);
  const modalDataStructure = state().modal.data;

  // populate data
  modalDataStructure.execution_time.value = 0.009411;
  modalDataStructure.system_output.value = 'Failure/Error: is_expected.to eq(3)\n\n';
  modalDataStructure.class.value = 'link';

  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      title: 'Test#sum when a is 1 and b is 2 returns summary',
      modalData: modalDataStructure,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders code block', () => {
    expect(vm.$el.querySelector('code').textContent).toEqual(modalDataStructure.system_output.value);
  });

  it('renders link', () => {
    expect(vm.$el.querySelector('.js-modal-link').getAttribute('href')).toEqual(modalDataStructure.class.value);
    expect(trimText(vm.$el.querySelector('.js-modal-link').textContent)).toEqual(modalDataStructure.class.value);
  });

  it('renders miliseconds', () => {
    expect(vm.$el.textContent).toContain(`${modalDataStructure.execution_time.value} ms`);
  });

  it('render title', () => {
    expect(trimText(vm.$el.querySelector('.modal-title').textContent)).toEqual('Test#sum when a is 1 and b is 2 returns summary');
  });
});
