import Vue from 'vue';
import editFormButtons from '~/sidebar/components/confidential/edit_form_buttons.vue';

describe('Edit Form Buttons', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(editFormButtons);
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

  it('renders on or off text based on confidentiality', () => {
    expect(
      vm1.$el.innerHTML.includes('Turn Off'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('Turn On'),
    ).toBe(true);
  });
});
