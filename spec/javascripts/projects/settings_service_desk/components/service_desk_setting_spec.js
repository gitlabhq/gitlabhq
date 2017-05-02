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

  describe('when isEnabled=true', () => {
    let el;

    describe('only isEnabled', () => {
      describe('as project admin', () => {
        beforeEach(() => {
          vm = createComponent({
            isEnabled: true,
          });
          el = vm.$el;
        });

        it('should see activation checkbox (not disabled)', () => {
          expect(vm.$refs['enabled-checkbox'].getAttribute('disabled')).toEqual(null);
        });

        it('should see main panel with the email info', () => {
          expect(el.querySelector('.panel')).toBeDefined();
        });

        it('should see loading spinner', () => {
          expect(el.querySelector('.fa-spinner')).toBeDefined();
          expect(el.querySelector('.fa-exclamation-circle')).toBeNull();
          expect(vm.$refs['service-desk-incoming-email']).toBeUndefined();
        });
      });
    });

    describe('with incomingEmail', () => {
      beforeEach(() => {
        vm = createComponent({
          isEnabled: true,
          incomingEmail: 'foo@bar.com',
        });
        el = vm.$el;
      });

      it('should see email', () => {
        expect(vm.$refs['service-desk-incoming-email'].textContent.trim()).toEqual('foo@bar.com');
        expect(el.querySelector('.fa-spinner')).toBeNull();
        expect(el.querySelector('.fa-exclamation-circle')).toBeNull();
      });
    });

    describe('with fetchError', () => {
      beforeEach(() => {
        vm = createComponent({
          isEnabled: true,
          fetchError: new Error('some-fake-failure'),
        });
        el = vm.$el;
      });

      it('should see error message', () => {
        expect(el.querySelector('.fa-exclamation-circle')).toBeDefined();
        expect(el.querySelector('.panel-body').textContent.trim()).toEqual('An error occurred while fetching the incoming email');
        expect(el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$refs['service-desk-incoming-email']).toBeUndefined();
      });
    });
  });

  describe('when isEnabled=false', () => {
    let el;

    beforeEach(() => {
      vm = createComponent({
        isEnabled: false,
      });
      el = vm.$el;
    });

    it('should not see panel', () => {
      expect(el.querySelector('.panel')).toBeNull();
    });

    it('should not see warning message', () => {
      expect(vm.$refs['recommend-protect-email-from-spam-message']).toBeUndefined();
    });
  });

  describe('methods', () => {
    describe('onCheckboxToggle', () => {
      let onCheckboxToggleSpy;

      beforeEach(() => {
        onCheckboxToggleSpy = jasmine.createSpy('spy');
        eventHub.$on('serviceDeskEnabledCheckboxToggled', onCheckboxToggleSpy);

        vm = createComponent({
          isEnabled: false,
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
  });
});
