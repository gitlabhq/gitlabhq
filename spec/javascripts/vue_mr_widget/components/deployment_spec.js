import Vue from 'vue';
import deploymentComponent from '~/vue_merge_request_widget/components/deployment.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import { getTimeago } from '~/lib/utils/datetime_utility';

const deploymentMockData = {
  id: 15,
  name: 'review/diplo',
  url: '/root/acets-review-apps/environments/15',
  stop_url: '/root/acets-review-apps/environments/15/stop',
  metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
  metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
  external_url: 'http://diplo.',
  external_url_formatted: 'diplo.',
  deployed_at: '2017-03-22T22:44:42.258Z',
  deployed_at_formatted: 'Mar 22, 2017 10:44pm',
};
const createComponent = () => {
  const Component = Vue.extend(deploymentComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: { deployment: { ...deploymentMockData } },
  });
};

describe('Deployment component', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
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
  });

  describe('methods', () => {
    describe('stopEnvironment', () => {
      const url = '/foo/bar';
      const returnPromise = () => new Promise((resolve) => {
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

      it('should show a confirm dialog and call service.stopEnvironment when confirmed', (done) => {
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
  });

  describe('template', () => {
    let el;

    beforeEach(() => {
      vm = createComponent(deploymentMockData);
      el = vm.$el;
    });

    it('renders deployment name', () => {
      expect(el.querySelector('.js-deploy-meta').getAttribute('href')).toEqual(deploymentMockData.url);
      expect(el.querySelector('.js-deploy-meta').innerText).toContain(deploymentMockData.name);
    });

    it('renders external URL', () => {
      expect(el.querySelector('.js-deploy-url').getAttribute('href')).toEqual(deploymentMockData.external_url);
      expect(el.querySelector('.js-deploy-url').innerText).toContain(deploymentMockData.external_url_formatted);
    });

    it('renders stop button', () => {
      expect(el.querySelector('.btn')).not.toBeNull();
    });

    it('renders deployment time', () => {
      expect(el.querySelector('.js-deploy-time').innerText).toContain(vm.deployTimeago);
    });

    it('renders metrics component', () => {
      expect(el.querySelector('.js-mr-memory-usage')).not.toBeNull();
    });
  });
});
