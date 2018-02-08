import Vue from 'vue';
import confirmationInput from '~/vue_shared/components/confirmation_input.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Confirmation input component', () => {
  const Component = Vue.extend(confirmationInput);
  const props = {
    inputId: 'dummy-id',
    confirmationKey: 'confirmation-key',
    confirmationValue: 'confirmation-value',
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    beforeEach(() => {
      vm = mountComponent(Component, props);
    });

    it('sets id of the input field to inputId', () => {
      expect(vm.$refs.enteredValue.id).toBe(props.inputId);
    });

    it('sets name of the input field to confirmationKey', () => {
      expect(vm.$refs.enteredValue.name).toBe(props.confirmationKey);
    });
  });

  describe('computed', () => {
    describe('inputLabel', () => {
      it('escapes confirmationValue by default', () => {
        vm = mountComponent(Component, { ...props, confirmationValue: 'n<e></e>ds escap"ng' });
        expect(vm.inputLabel).toBe('Type <code>n&lt;e&gt;&lt;/e&gt;ds escap&quot;ng</code> to confirm:');
      });

      it('does not escape confirmationValue if escapeValue is false', () => {
        vm = mountComponent(Component, { ...props, confirmationValue: 'n<e></e>ds escap"ng', shouldEscapeConfirmationValue: false });
        expect(vm.inputLabel).toBe('Type <code>n<e></e>ds escap"ng</code> to confirm:');
      });
    });
  });

  describe('methods', () => {
    describe('hasCorrectValue', () => {
      beforeEach(() => {
        vm = mountComponent(Component, props);
      });

      it('returns false if entered value is incorrect', () => {
        vm.$refs.enteredValue.value = 'incorrect';
        expect(vm.hasCorrectValue()).toBe(false);
      });

      it('returns true if entered value is correct', () => {
        vm.$refs.enteredValue.value = props.confirmationValue;
        expect(vm.hasCorrectValue()).toBe(true);
      });
    });
  });
});
