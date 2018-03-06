import Vue from 'vue';
import eventHub from '~/clusters/event_hub';
import {
  APPLICATION_NOT_INSTALLABLE,
  APPLICATION_SCHEDULED,
  APPLICATION_INSTALLABLE,
  APPLICATION_INSTALLING,
  APPLICATION_INSTALLED,
  APPLICATION_ERROR,
  REQUEST_LOADING,
  REQUEST_SUCCESS,
  REQUEST_FAILURE,
} from '~/clusters/constants';
import applicationRow from '~/clusters/components/application_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { DEFAULT_APPLICATION_STATE } from '../services/mock_data';

describe('Application Row', () => {
  let vm;
  let ApplicationRow;

  beforeEach(() => {
    ApplicationRow = Vue.extend(applicationRow);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Title', () => {
    it('shows title', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        titleLink: null,
      });
      const title = vm.$el.querySelector('.js-cluster-application-title');

      expect(title.tagName).toEqual('SPAN');
      expect(title.textContent.trim()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });

    it('shows title link', () => {
      expect(DEFAULT_APPLICATION_STATE.titleLink).toBeDefined();

      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
      });
      const title = vm.$el.querySelector('.js-cluster-application-title');

      expect(title.tagName).toEqual('A');
      expect(title.textContent.trim()).toEqual(DEFAULT_APPLICATION_STATE.title);
    });
  });

  describe('Install button', () => {
    it('has indeterminate state on page load', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: null,
      });

      expect(vm.installButtonLabel).toBeUndefined();
    });

    it('has disabled "Install" when APPLICATION_NOT_INSTALLABLE', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_NOT_INSTALLABLE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has enabled "Install" when APPLICATION_INSTALLABLE', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('has loading "Installing" when APPLICATION_SCHEDULED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_SCHEDULED,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has loading "Installing" when APPLICATION_INSTALLING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLING,
      });

      expect(vm.installButtonLabel).toEqual('Installing');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has disabled "Installed" when APPLICATION_INSTALLED', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLED,
      });

      expect(vm.installButtonLabel).toEqual('Installed');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has enabled "Install" when APPLICATION_ERROR', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_ERROR,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('has loading "Install" when REQUEST_LOADING', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
        requestStatus: REQUEST_LOADING,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(true);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has disabled "Install" when REQUEST_SUCCESS', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
        requestStatus: REQUEST_SUCCESS,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(true);
    });

    it('has enabled "Install" when REQUEST_FAILURE (so you can try installing again)', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
        requestStatus: REQUEST_FAILURE,
      });

      expect(vm.installButtonLabel).toEqual('Install');
      expect(vm.installButtonLoading).toEqual(false);
      expect(vm.installButtonDisabled).toEqual(false);
    });

    it('clicking install button emits event', () => {
      spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
      });
      const installButton = vm.$el.querySelector('.js-cluster-application-install-button');

      installButton.click();

      expect(eventHub.$emit).toHaveBeenCalledWith('installApplication', DEFAULT_APPLICATION_STATE.id);
    });

    it('clicking disabled install button emits nothing', () => {
      spyOn(eventHub, '$emit');
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLING,
      });
      const installButton = vm.$el.querySelector('.js-cluster-application-install-button');

      expect(vm.installButtonDisabled).toEqual(true);

      installButton.click();

      expect(eventHub.$emit).not.toHaveBeenCalled();
    });
  });

  describe('Error block', () => {
    it('does not show error block when there is no error', () => {
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: null,
        requestStatus: null,
      });
      const generalErrorMessage = vm.$el.querySelector('.js-cluster-application-general-error-message');

      expect(generalErrorMessage).toBeNull();
    });

    it('shows status reason when APPLICATION_ERROR', () => {
      const statusReason = 'We broke it 0.0';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_ERROR,
        statusReason,
      });
      const generalErrorMessage = vm.$el.querySelector('.js-cluster-application-general-error-message');
      const statusErrorMessage = vm.$el.querySelector('.js-cluster-application-status-error-message');

      expect(generalErrorMessage.textContent.trim()).toEqual(`Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`);
      expect(statusErrorMessage.textContent.trim()).toEqual(statusReason);
    });

    it('shows request reason when REQUEST_FAILURE', () => {
      const requestReason = 'We broke thre request 0.0';
      vm = mountComponent(ApplicationRow, {
        ...DEFAULT_APPLICATION_STATE,
        status: APPLICATION_INSTALLABLE,
        requestStatus: REQUEST_FAILURE,
        requestReason,
      });
      const generalErrorMessage = vm.$el.querySelector('.js-cluster-application-general-error-message');
      const requestErrorMessage = vm.$el.querySelector('.js-cluster-application-request-error-message');

      expect(generalErrorMessage.textContent.trim()).toEqual(`Something went wrong while installing ${DEFAULT_APPLICATION_STATE.title}`);
      expect(requestErrorMessage.textContent.trim()).toEqual(requestReason);
    });
  });
});
