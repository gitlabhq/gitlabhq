import Vue from 'vue';
import deploymentComponent from '~/vue_merge_request_widget/components/deployment.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import { getTimeago } from '~/lib/utils/datetime_utility';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Deployment component', () => {
  const Component = Vue.extend(deploymentComponent);
  const deploymentMockData = {
    id: 15,
    name: 'review/diplo',
    url: '/root/review-apps/environments/15',
    stop_url: '/root/review-apps/environments/15/stop',
    metrics_url: '/root/review-apps/environments/15/deployments/1/metrics',
    metrics_monitoring_url: '/root/review-apps/environments/15/metrics',
    external_url: 'http://gitlab.com.',
    external_url_formatted: 'gitlab',
    deployed_at: '2017-03-22T22:44:42.258Z',
    deployed_at_formatted: 'Mar 22, 2017 10:44pm',
    changes: [
      {
        path: 'index.html',
        external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/index.html',
      },
      {
        path: 'imgs/gallery.html',
        external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
      },
      {
        path: 'about/',
        external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/about/',
      },
    ],
  };

  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { deployment: { ...deploymentMockData } });
    });

    describe('deployTimeago', () => {
      it('return formatted date', () => {
        const readable = getTimeago().format(deploymentMockData.deployed_at);

        expect(vm.deployTimeago).toEqual(readable);
      });
    });

    describe('hasExternalUrls', () => {
      it('should return true', () => {
        expect(vm.hasExternalUrls).toEqual(true);
      });

      it('should return false when deployment has no external_url_formatted', () => {
        vm.deployment.external_url_formatted = null;

        expect(vm.hasExternalUrls).toEqual(false);
      });

      it('should return false when deployment has no external_url', () => {
        vm.deployment.external_url = null;

        expect(vm.hasExternalUrls).toEqual(false);
      });
    });

    describe('hasDeploymentTime', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentTime).toEqual(true);
      });

      it('should return false when deployment has no deployed_at', () => {
        vm.deployment.deployed_at = null;

        expect(vm.hasDeploymentTime).toEqual(false);
      });

      it('should return false when deployment has no deployed_at_formatted', () => {
        vm.deployment.deployed_at_formatted = null;

        expect(vm.hasDeploymentTime).toEqual(false);
      });
    });

    describe('hasDeploymentMeta', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentMeta).toEqual(true);
      });

      it('should return false when deployment has no url', () => {
        vm.deployment.url = null;

        expect(vm.hasDeploymentMeta).toEqual(false);
      });

      it('should return false when deployment has no name', () => {
        vm.deployment.name = null;

        expect(vm.hasDeploymentMeta).toEqual(false);
      });
    });

    describe('stopEnvironment', () => {
      const url = '/foo/bar';
      const returnPromise = () =>
        new Promise(resolve => {
          resolve({
            data: {
              redirect_url: url,
            },
          });
        });
      const mockStopEnvironment = () => {
        vm.stopEnvironment(deploymentMockData);
        return vm;
      };

      it('should show a confirm dialog and call service.stopEnvironment when confirmed', done => {
        spyOn(window, 'confirm').and.returnValue(true);
        spyOn(MRWidgetService, 'stopEnvironment').and.returnValue(returnPromise(true));
        const visitUrl = spyOnDependency(deploymentComponent, 'visitUrl').and.returnValue(true);
        vm = mockStopEnvironment();

        expect(window.confirm).toHaveBeenCalled();
        expect(MRWidgetService.stopEnvironment).toHaveBeenCalledWith(deploymentMockData.stop_url);
        setTimeout(() => {
          expect(visitUrl).toHaveBeenCalledWith(url);
          done();
        }, 333);
      });

      it('should show a confirm dialog but should not work if the dialog is rejected', () => {
        spyOn(window, 'confirm').and.returnValue(false);
        spyOn(MRWidgetService, 'stopEnvironment').and.returnValue(returnPromise(false));
        vm = mockStopEnvironment();

        expect(window.confirm).toHaveBeenCalled();
        expect(MRWidgetService.stopEnvironment).not.toHaveBeenCalled();
      });
    });

    it('renders deployment name', () => {
      expect(vm.$el.querySelector('.js-deploy-meta').getAttribute('href')).toEqual(
        deploymentMockData.url,
      );

      expect(vm.$el.querySelector('.js-deploy-meta').innerText).toContain(deploymentMockData.name);
    });

    it('renders external URL', () => {
      expect(vm.$el.querySelector('.js-deploy-url').getAttribute('href')).toEqual(
        deploymentMockData.external_url,
      );

      expect(vm.$el.querySelector('.js-deploy-url').innerText).toContain('View app');
    });

    it('renders stop button', () => {
      expect(vm.$el.querySelector('.btn')).not.toBeNull();
    });

    it('renders deployment time', () => {
      expect(vm.$el.querySelector('.js-deploy-time').innerText).toContain(vm.deployTimeago);
    });

    it('renders metrics component', () => {
      expect(vm.$el.querySelector('.js-mr-memory-usage')).not.toBeNull();
    });
  });

  describe('without changes', () => {
    beforeEach(() => {
      delete deploymentMockData.changes;

      vm = mountComponent(Component, { deployment: { ...deploymentMockData } });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(vm.$el.querySelector('.js-mr-wigdet-deployment-dropdown')).toBeNull();
      expect(vm.$el.querySelector('.js-deploy-url-feature-flag')).not.toBeNull();
    });
  });

  describe('deployment status', () => {
    describe('running', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'running' }),
        });
      });

      it('renders information about running deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain('Deploying to');
      });

      it('renders disabled stop button', () => {
        expect(vm.$el.querySelector('.js-stop-env').getAttribute('disabled')).toBe('disabled');
      });
    });

    describe('success', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'success' }),
        });
      });

      it('renders information about finished deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain('Deployed to');
      });
    });

    describe('failed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'failed' }),
        });
      });

      it('renders information about finished deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain(
          'Failed to deploy to',
        );
      });
    });
  });
});
