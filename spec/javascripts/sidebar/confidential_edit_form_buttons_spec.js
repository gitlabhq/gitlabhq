import Vue from 'vue';
import editForm from '~/sidebar/components/confidential/edit_form.vue';

describe('Edit Form Dropdown', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(editForm);
    const toggleForm = () => { };
    const updateConfidentialAttribute = () => { };

    vm1 = new Component({
      propsData: {
        isConfidential: true,
        toggleForm,
        updateConfidentialAttribute,
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isConfidential: false,
        toggleForm,
        updateConfidentialAttribute,
      },
    }).$mount();
  });

  it('renders on the appropriate warning text', () => {
    expect(
      vm1.$el.innerHTML.includes('You are going to turn off the confidentiality.'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('You are going to turn on the confidentiality.'),
    ).toBe(true);
  });
});
