import Clusters from '~/clusters/clusters_bundle';
import {
  REQUEST_SUBMITTED,
  REQUEST_FAILURE,
  APPLICATION_STATUS,
  INGRESS_DOMAIN_SUFFIX,
} from '~/clusters/constants';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';

describe('Clusters', () => {
  let cluster;
  preloadFixtures('clusters/show_cluster.html');

  beforeEach(() => {
    loadFixtures('clusters/show_cluster.html');
    cluster = new Clusters();
  });

  afterEach(() => {
    cluster.destroy();
  });

  describe('toggle', () => {
    it('should update the button and the input field on click', done => {
      const toggleButton = document.querySelector(
        '.js-cluster-enable-toggle-area .js-project-feature-toggle',
      );
      const toggleInput = document.querySelector(
        '.js-cluster-enable-toggle-area .js-project-feature-toggle-input',
      );

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(toggleButton.classList).not.toContain('is-checked');

          expect(toggleInput.getAttribute('value')).toEqual('false');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('showToken', () => {
    it('should update token field type', () => {
      cluster.showTokenButton.click();

      expect(cluster.tokenField.getAttribute('type')).toEqual('text');

      cluster.showTokenButton.click();

      expect(cluster.tokenField.getAttribute('type')).toEqual('password');
    });

    it('should update show token button text', () => {
      cluster.showTokenButton.click();

      expect(cluster.showTokenButton.textContent).toEqual('Hide');

      cluster.showTokenButton.click();

      expect(cluster.showTokenButton.textContent).toEqual('Show');
    });
  });

  describe('checkForNewInstalls', () => {
    const INITIAL_APP_MAP = {
      helm: { status: null, title: 'Helm Tiller' },
      ingress: { status: null, title: 'Ingress' },
      runner: { status: null, title: 'GitLab Runner' },
    };

    it('does not show alert when things transition from initial null state to something', () => {
      cluster.checkForNewInstalls(INITIAL_APP_MAP, {
        ...INITIAL_APP_MAP,
        helm: { status: APPLICATION_STATUS.INSTALLABLE, title: 'Helm Tiller' },
      });

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).toBeNull();
    });

    it('shows an alert when something gets newly installed', () => {
      cluster.checkForNewInstalls(
        {
          ...INITIAL_APP_MAP,
          helm: { status: APPLICATION_STATUS.INSTALLING, title: 'Helm Tiller' },
        },
        {
          ...INITIAL_APP_MAP,
          helm: { status: APPLICATION_STATUS.INSTALLED, title: 'Helm Tiller' },
        },
      );

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual(
        'Helm Tiller was successfully installed on your Kubernetes cluster',
      );
    });

    it('shows an alert when multiple things gets newly installed', () => {
      cluster.checkForNewInstalls(
        {
          ...INITIAL_APP_MAP,
          helm: { status: APPLICATION_STATUS.INSTALLING, title: 'Helm Tiller' },
          ingress: { status: APPLICATION_STATUS.INSTALLABLE, title: 'Ingress' },
        },
        {
          ...INITIAL_APP_MAP,
          helm: { status: APPLICATION_STATUS.INSTALLED, title: 'Helm Tiller' },
          ingress: { status: APPLICATION_STATUS.INSTALLED, title: 'Ingress' },
        },
      );

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');

      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual(
        'Helm Tiller, Ingress was successfully installed on your Kubernetes cluster',
      );
    });
  });

  describe('updateContainer', () => {
    describe('when creating cluster', () => {
      it('should show the creating container', () => {
        cluster.updateContainer(null, 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeFalsy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
      });

      it('should continue to show `creating` banner with subsequent updates of the same status', () => {
        cluster.updateContainer('creating', 'creating');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeFalsy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
      });
    });

    describe('when cluster is created', () => {
      it('should show the success container and fresh the page', () => {
        cluster.updateContainer(null, 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeFalsy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
      });

      it('should not show a banner when status is already `created`', () => {
        cluster.updateContainer('created', 'created');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeTruthy();
      });
    });

    describe('when cluster has error', () => {
      it('should show the error container', () => {
        cluster.updateContainer(null, 'errored', 'this is an error');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeFalsy();

        expect(cluster.errorReasonContainer.textContent).toContain('this is an error');
      });

      it('should show `error` banner when previously `creating`', () => {
        cluster.updateContainer('creating', 'errored');

        expect(cluster.creatingContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.successContainer.classList.contains('hidden')).toBeTruthy();

        expect(cluster.errorContainer.classList.contains('hidden')).toBeFalsy();
      });
    });
  });

  describe('installApplication', () => {
    it('tries to install helm', () => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(null);

      cluster.installApplication({ id: 'helm' });

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_SUBMITTED);
      expect(cluster.store.state.applications.helm.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('helm', undefined);
    });

    it('tries to install ingress', () => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());

      expect(cluster.store.state.applications.ingress.requestStatus).toEqual(null);

      cluster.installApplication({ id: 'ingress' });

      expect(cluster.store.state.applications.ingress.requestStatus).toEqual(REQUEST_SUBMITTED);
      expect(cluster.store.state.applications.ingress.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('ingress', undefined);
    });

    it('tries to install runner', () => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());

      expect(cluster.store.state.applications.runner.requestStatus).toEqual(null);

      cluster.installApplication({ id: 'runner' });

      expect(cluster.store.state.applications.runner.requestStatus).toEqual(REQUEST_SUBMITTED);
      expect(cluster.store.state.applications.runner.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('runner', undefined);
    });

    it('tries to install jupyter', () => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());

      expect(cluster.store.state.applications.jupyter.requestStatus).toEqual(null);
      cluster.installApplication({
        id: 'jupyter',
        params: { hostname: cluster.store.state.applications.jupyter.hostname },
      });

      expect(cluster.store.state.applications.jupyter.requestStatus).toEqual(REQUEST_SUBMITTED);
      expect(cluster.store.state.applications.jupyter.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('jupyter', {
        hostname: cluster.store.state.applications.jupyter.hostname,
      });
    });

    it('sets error request status when the request fails', done => {
      spyOn(cluster.service, 'installApplication').and.returnValue(
        Promise.reject(new Error('STUBBED ERROR')),
      );

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(null);

      cluster.installApplication({ id: 'helm' });

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_SUBMITTED);
      expect(cluster.store.state.applications.helm.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalled();

      getSetTimeoutPromise()
        .then(() => {
          expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_FAILURE);
          expect(cluster.store.state.applications.helm.requestReason).toBeDefined();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('handleSuccess', () => {
    beforeEach(() => {
      spyOn(cluster.store, 'updateStateFromServer');
      spyOn(cluster, 'toggleIngressDomainHelpText');
      spyOn(cluster, 'checkForNewInstalls');
      spyOn(cluster, 'updateContainer');

      cluster.handleSuccess({ data: {} });
    });

    it('updates clusters store', () => {
      expect(cluster.store.updateStateFromServer).toHaveBeenCalled();
    });

    it('checks for new installable apps', () => {
      expect(cluster.checkForNewInstalls).toHaveBeenCalled();
    });

    it('toggles ingress domain help text', () => {
      expect(cluster.toggleIngressDomainHelpText).toHaveBeenCalled();
    });

    it('updates message containers', () => {
      expect(cluster.updateContainer).toHaveBeenCalled();
    });
  });

  describe('toggleIngressDomainHelpText', () => {
    const { INSTALLED, INSTALLABLE, NOT_INSTALLABLE } = APPLICATION_STATUS;

    const ingressPreviousState = { status: INSTALLABLE };
    const ingressNewState = { status: INSTALLED, externalIp: '127.0.0.1' };

    describe(`when ingress application new status is ${INSTALLED}`, () => {
      beforeEach(() => {
        ingressNewState.status = INSTALLED;
        cluster.toggleIngressDomainHelpText(ingressPreviousState, ingressNewState);
      });

      it('displays custom domain help text', () => {
        expect(cluster.ingressDomainHelpText.classList.contains('hide')).toEqual(false);
      });

      it('updates ingress external ip address', () => {
        expect(cluster.ingressDomainSnippet.textContent).toEqual(
          `${ingressNewState.externalIp}${INGRESS_DOMAIN_SUFFIX}`,
        );
      });
    });

    describe(`when ingress application new status is different from ${INSTALLED}`, () => {
      it('hides custom domain help text', () => {
        ingressNewState.status = NOT_INSTALLABLE;
        cluster.ingressDomainHelpText.classList.remove('hide');

        cluster.toggleIngressDomainHelpText(ingressPreviousState, ingressNewState);

        expect(cluster.ingressDomainHelpText.classList.contains('hide')).toEqual(true);
      });
    });

    describe('when ingress application new status and old status are the same', () => {
      it('does not modify custom domain help text', () => {
        ingressPreviousState.status = INSTALLED;
        ingressNewState.status = ingressPreviousState.status;

        cluster.toggleIngressDomainHelpText(ingressPreviousState, ingressNewState);

        expect(cluster.ingressDomainHelpText.classList.contains('hide')).toEqual(true);
      });
    });
  });
});
