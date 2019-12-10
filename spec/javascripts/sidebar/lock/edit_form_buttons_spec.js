import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import editFormButtons from '~/sidebar/components/lock/edit_form_buttons.vue';

describe('EditFormButtons', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(editFormButtons);
    const toggleForm = () => {};
    const updateLockedAttribute = () => {};

    vm1 = mountComponent(Component, {
      isLocked: true,
      toggleForm,
      updateLockedAttribute,
    });

    vm2 = mountComponent(Component, {
      isLocked: false,
      toggleForm,
      updateLockedAttribute,
    });
  });

  it('renders unlock or lock text based on locked state', () => {
    expect(vm1.$el.innerHTML.includes('Unlock')).toBe(true);

    expect(vm2.$el.innerHTML.includes('Lock')).toBe(true);
  });
});
