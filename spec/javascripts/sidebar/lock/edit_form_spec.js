import Vue from 'vue';
import editForm from '~/sidebar/components/lock/edit_form.vue';

describe('EditForm', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(editForm);
    const toggleForm = () => { };
    const updateLockedAttribute = () => { };

    vm1 = new Component({
      propsData: {
        isLocked: true,
        toggleForm,
        updateLockedAttribute,
        issuableType: 'issue',
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isLocked: false,
        toggleForm,
        updateLockedAttribute,
        issuableType: 'merge_request',
      },
    }).$mount();
  });

  it('renders on the appropriate warning text', () => {
    expect(
      vm1.$el.innerHTML.includes('Unlock this issue?'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('Lock this merge request?'),
    ).toBe(true);
  });
});
