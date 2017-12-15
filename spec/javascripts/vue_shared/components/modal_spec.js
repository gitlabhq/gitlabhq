import Vue from 'vue';
import modal from '~/vue_shared/components/modal.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Modal', () => {
  it('does not render a primary button if no primaryButtonLabel', () => {
    const modalComponent = Vue.extend(modal);
    const vm = mountComponent(modalComponent);

    expect(vm.$el.querySelector('.js-primary-button')).toBeNull();
  });
});
