import Vue from 'vue';
import editFormButtons from '~/sidebar/components/lock/edit_form_buttons.vue';

describe('EditFormButtons', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(editFormButtons);
    const toggleForm = () => { };
    const updateLockedAttribute = () => { };

    vm1 = new Component({
      propsData: {
        isLocked: true,
        toggleForm,
        updateLockedAttribute,
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isLocked: false,
        toggleForm,
        updateLockedAttribute,
      },
    }).$mount();
  });

  it('renders unlock or lock text based on locked state', () => {
    expect(
      vm1.$el.innerHTML.includes('Unlock'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('Lock'),
    ).toBe(true);
  });
});
