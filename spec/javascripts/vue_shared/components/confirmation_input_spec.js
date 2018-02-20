import Vue from 'vue';
import confirmationInput from '~/vue_shared/components/confirmation_input.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Confirmation input component', () => {
  const Component = Vue.extend(confirmationInput);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    describe('confirmationValue', () => {
      const confirmationValue = 'something to confirm';

      beforeEach(() => {
        vm = mountComponent(Component, {
          confirmationValue,
        });
      });

      it('displays the confirmation value', () => {
        expect(vm.$el.innerText).toContain(confirmationValue);
      });
    });
  });

  describe('computed', () => {
    describe('inputLabel', () => {
      const confirmationValue = 'n<e></e>ds escap"ng';

      it('escapes confirmationValue by default', () => {
        vm = mountComponent(Component, {
          confirmationValue,
        });
        expect(vm.inputLabel).toBe('Type <code>n&lt;e&gt;&lt;/e&gt;ds escap&quot;ng</code> to confirm:');
      });

      it('does not escape confirmationValue if escapeValue is false', () => {
        vm = mountComponent(Component, {
          confirmationValue,
          shouldEscapeConfirmationValue: false,
        });
        expect(vm.inputLabel).toBe(`Type <code>${confirmationValue}</code> to confirm:`);
      });
    });
  });

  describe('methods', () => {
    describe('onInput', () => {
      const confirmationValue = 'some dummy value';
      const dummyEvent = inputValue => ({
        target: {
          value: inputValue,
        },
      });

      beforeEach(() => {
        vm = mountComponent(Component, {
          confirmationValue,
        });
        spyOn(vm, '$emit');
      });

      it('triggers confirmed event with false if entered value is incorrect', () => {
        vm.onInput(dummyEvent('this is incorrect'));

        expect(vm.$emit).toHaveBeenCalledWith('confirmed', false);
      });

      it('triggers confirmed event with true if entered value is correct', () => {
        vm.onInput(dummyEvent(confirmationValue));

        expect(vm.$emit).toHaveBeenCalledWith('confirmed', true);
      });
    });
  });
});
