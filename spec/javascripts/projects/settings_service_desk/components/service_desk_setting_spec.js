import Vue from 'vue';
import eventHub from '~/projects/settings_service_desk/event_hub';
import ServiceDeskSetting from '~/projects/settings_service_desk/components/service_desk_setting';

const createComponent = (propsData) => {
  const Component = Vue.extend(ServiceDeskSetting);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('ServiceDeskSetting', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('when isActivated=true', () => {
    let el;

    describe('only isActivated', () => {
      beforeEach(() => {
        vm = createComponent({
          isActivated: true,
        });
        el = vm.$el;
      });

      it('see main panel with the email info', () => {
        expect(el.querySelector('.panel')).toBeDefined();
      });

      it('see loading spinner', () => {
        expect(el.querySelector('.fa-spinner')).toBeDefined();
        expect(el.querySelector('.fa-exclamation-circle')).toBeNull();
        expect(vm.$refs['service-desk-incoming-email']).toBeUndefined();
      });

      it('see warning message', () => {
        expect(el.querySelector('.settings-message')).toBeDefined();
      });
    });

    describe('with incomingEmail', () => {
      beforeEach(() => {
        vm = createComponent({
          isActivated: true,
          incomingEmail: 'foo@bar.com',
        });
        el = vm.$el;
      });

      it('see email', () => {
        expect(vm.$refs['service-desk-incoming-email'].textContent.trim()).toEqual('foo@bar.com');
        expect(el.querySelector('.fa-spinner')).toBeNull();
        expect(el.querySelector('.fa-exclamation-circle')).toBeNull();
      });
    });

    describe('with fetchError', () => {
      beforeEach(() => {
        vm = createComponent({
          isActivated: true,
          fetchError: new Error('some-fake-failure'),
        });
        el = vm.$el;
      });

      it('see error message', () => {
        expect(el.querySelector('.fa-exclamation-circle')).toBeDefined();
        expect(el.querySelector('.panel-body').textContent.trim()).toEqual('An error occurred while fetching the incoming email');
        expect(el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$refs['service-desk-incoming-email']).toBeUndefined();
      });
    });
  });

  describe('when isActivated=false', () => {
    let el;

    beforeEach(() => {
      vm = createComponent({
        isActivated: false,
      });
      el = vm.$el;
    });

    it('should not see panel', () => {
      expect(el.querySelector('.panel')).toBeNull();
    });

    it('should not see warning message', () => {
      expect(el.querySelector('.settings-message')).toBeNull();
    });
  });

  describe('methods', () => {
    describe('onCheckboxToggle', () => {
      let onCheckboxToggleSpy;

      beforeEach(() => {
        onCheckboxToggleSpy = jasmine.createSpy('spy');
        eventHub.$on('serviceDeskEnabledCheckboxToggled', onCheckboxToggleSpy);

        vm = createComponent({
          isActivated: false,
        });
      });

      afterEach(() => {
        eventHub.$off('serviceDeskEnabledCheckboxToggled', onCheckboxToggleSpy);
      });

      it('when getting checked', () => {
        expect(onCheckboxToggleSpy).not.toHaveBeenCalled();
        vm.onCheckboxToggle({
          target: {
            checked: true,
          },
        });
        expect(onCheckboxToggleSpy).toHaveBeenCalledWith(true);
      });

      it('when getting unchecked', () => {
        expect(onCheckboxToggleSpy).not.toHaveBeenCalled();
        vm.onCheckboxToggle({
          target: {
            checked: false,
          },
        });
        expect(onCheckboxToggleSpy).toHaveBeenCalledWith(false);
      });
    });

    describe('copyIncomingEmail', () => {
      beforeEach(() => {
        vm = createComponent({
          isActivated: true,
          incomingEmail: 'foo@bar.com',
        });
      });

      it('copies text to clipboard');
    });
  });
});
