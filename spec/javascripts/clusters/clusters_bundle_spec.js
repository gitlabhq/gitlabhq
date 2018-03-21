import Clusters from '~/clusters/clusters_bundle';
import {
  APPLICATION_INSTALLABLE,
  APPLICATION_INSTALLING,
  APPLICATION_INSTALLED,
  REQUEST_LOADING,
  REQUEST_SUCCESS,
  REQUEST_FAILURE,
} from '~/clusters/constants';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';

describe('Clusters', () => {
  let cluster;
  preloadFixtures('clusters/show_cluster.html.raw');

  beforeEach(() => {
    loadFixtures('clusters/show_cluster.html.raw');
    cluster = new Clusters();
  });

  afterEach(() => {
    cluster.destroy();
  });

  describe('toggle', () => {
    it('should update the button and the input field on click', (done) => {
      const toggleButton = document.querySelector('.js-cluster-enable-toggle-area .js-project-feature-toggle');
      const toggleInput = document.querySelector('.js-cluster-enable-toggle-area .js-project-feature-toggle-input');

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(
            toggleButton.classList,
          ).not.toContain('is-checked');

          expect(
            toggleInput.getAttribute('value'),
          ).toEqual('false');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('showToken', () => {
    it('should update tye field type', () => {
      cluster.showTokenButton.click();
      expect(
        cluster.tokenField.getAttribute('type'),
      ).toEqual('text');

      cluster.showTokenButton.click();
      expect(
        cluster.tokenField.getAttribute('type'),
      ).toEqual('password');
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
        helm: { status: APPLICATION_INSTALLABLE, title: 'Helm Tiller' },
      });

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');
      expect(flashMessage).toBeNull();
    });

    it('shows an alert when something gets newly installed', () => {
      cluster.checkForNewInstalls({
        ...INITIAL_APP_MAP,
        helm: { status: APPLICATION_INSTALLING, title: 'Helm Tiller' },
      }, {
        ...INITIAL_APP_MAP,
        helm: { status: APPLICATION_INSTALLED, title: 'Helm Tiller' },
      });

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');
      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual('Helm Tiller was successfully installed on your Kubernetes cluster');
    });

    it('shows an alert when multiple things gets newly installed', () => {
      cluster.checkForNewInstalls({
        ...INITIAL_APP_MAP,
        helm: { status: APPLICATION_INSTALLING, title: 'Helm Tiller' },
        ingress: { status: APPLICATION_INSTALLABLE, title: 'Ingress' },
      }, {
        ...INITIAL_APP_MAP,
        helm: { status: APPLICATION_INSTALLED, title: 'Helm Tiller' },
        ingress: { status: APPLICATION_INSTALLED, title: 'Ingress' },
      });

      const flashMessage = document.querySelector('.js-cluster-application-notice .flash-text');
      expect(flashMessage).not.toBeNull();
      expect(flashMessage.textContent.trim()).toEqual('Helm Tiller, Ingress was successfully installed on your Kubernetes cluster');
    });
  });

  describe('updateContainer', () => {
    describe('when creating cluster', () => {
      it('should show the creating container', () => {
        cluster.updateContainer(null, 'creating');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeFalsy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });

      it('should continue to show `creating` banner with subsequent updates of the same status', () => {
        cluster.updateContainer('creating', 'creating');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeFalsy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });
    });

    describe('when cluster is created', () => {
      it('should show the success container and fresh the page', () => {
        cluster.updateContainer(null, 'created');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeFalsy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });

      it('should not show a banner when status is already `created`', () => {
        cluster.updateContainer('created', 'created');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });
    });

    describe('when cluster has error', () => {
      it('should show the error container', () => {
        cluster.updateContainer(null, 'errored', 'this is an error');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeFalsy();

        expect(
          cluster.errorReasonContainer.textContent,
        ).toContain('this is an error');
      });

      it('should show `error` banner when previously `creating`', () => {
        cluster.updateContainer('creating', 'errored');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeFalsy();
      });
    });
  });

  describe('installApplication', () => {
    it('tries to install helm', (done) => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());
      expect(cluster.store.state.applications.helm.requestStatus).toEqual(null);

      cluster.installApplication('helm');

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_LOADING);
      expect(cluster.store.state.applications.helm.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('helm');

      getSetTimeoutPromise()
        .then(() => {
          expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_SUCCESS);
          expect(cluster.store.state.applications.helm.requestReason).toEqual(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('tries to install ingress', (done) => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());
      expect(cluster.store.state.applications.ingress.requestStatus).toEqual(null);

      cluster.installApplication('ingress');

      expect(cluster.store.state.applications.ingress.requestStatus).toEqual(REQUEST_LOADING);
      expect(cluster.store.state.applications.ingress.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('ingress');

      getSetTimeoutPromise()
        .then(() => {
          expect(cluster.store.state.applications.ingress.requestStatus).toEqual(REQUEST_SUCCESS);
          expect(cluster.store.state.applications.ingress.requestReason).toEqual(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('tries to install runner', (done) => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.resolve());
      expect(cluster.store.state.applications.runner.requestStatus).toEqual(null);

      cluster.installApplication('runner');

      expect(cluster.store.state.applications.runner.requestStatus).toEqual(REQUEST_LOADING);
      expect(cluster.store.state.applications.runner.requestReason).toEqual(null);
      expect(cluster.service.installApplication).toHaveBeenCalledWith('runner');

      getSetTimeoutPromise()
        .then(() => {
          expect(cluster.store.state.applications.runner.requestStatus).toEqual(REQUEST_SUCCESS);
          expect(cluster.store.state.applications.runner.requestReason).toEqual(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets error request status when the request fails', (done) => {
      spyOn(cluster.service, 'installApplication').and.returnValue(Promise.reject(new Error('STUBBED ERROR')));
      expect(cluster.store.state.applications.helm.requestStatus).toEqual(null);

      cluster.installApplication('helm');

      expect(cluster.store.state.applications.helm.requestStatus).toEqual(REQUEST_LOADING);
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
});
