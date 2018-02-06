import Vue from 'vue';
import * as urlUtils from '~/lib/utils/url_utility';
import deploymentComponent from '~/vue_merge_request_widget/components/mr_widget_deployment';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import { getTimeago } from '~/lib/utils/datetime_utility';

const deploymentMockData = [
  {
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
  },
];
const createComponent = () => {
  const Component = Vue.extend(deploymentComponent);
  const mr = {
    deployments: deploymentMockData,
  };
  const service = {};

  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('MRWidgetDeployment', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = deploymentComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('methods', () => {
    let vm = createComponent();
    const deployment = deploymentMockData[0];

    describe('formatDate', () => {
      it('should work', () => {
        const readable = getTimeago().format(deployment.deployed_at);
        expect(vm.formatDate(deployment.deployed_at)).toEqual(readable);
      });
    });

    describe('hasExternalUrls', () => {
      it('should return true', () => {
        expect(vm.hasExternalUrls(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasExternalUrls()).toBeFalsy();
        expect(vm.hasExternalUrls({ external_url: 'Diplo' })).toBeFalsy();
        expect(vm.hasExternalUrls({ external_url_formatted: 'Diplo' })).toBeFalsy();
      });
    });

    describe('hasDeploymentTime', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentTime(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasDeploymentTime()).toBeFalsy();
        expect(vm.hasDeploymentTime({ deployed_at: 'Diplo' })).toBeFalsy();
        expect(vm.hasDeploymentTime({ deployed_at_formatted: 'Diplo' })).toBeFalsy();
      });
    });

    describe('hasDeploymentMeta', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentMeta(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasDeploymentMeta()).toBeFalsy();
        expect(vm.hasDeploymentMeta({ url: 'Diplo' })).toBeFalsy();
        expect(vm.hasDeploymentMeta({ name: 'Diplo' })).toBeFalsy();
      });
    });

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
        spyOn(urlUtils, 'visitUrl').and.returnValue(true);
        vm = mockStopEnvironment();

        expect(window.confirm).toHaveBeenCalled();
        expect(MRWidgetService.stopEnvironment).toHaveBeenCalledWith(deploymentMockData.stop_url);
        setTimeout(() => {
          expect(urlUtils.visitUrl).toHaveBeenCalledWith(url);
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
    let vm;
    let el;
    const [deployment] = deploymentMockData;

    beforeEach(() => {
      vm = createComponent(deploymentMockData);
      el = vm.$el;
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-widget-heading')).toBeTruthy();
      expect(el.querySelector('.js-icon-link')).toBeDefined();
      expect(el.querySelector('.js-deploy-meta').getAttribute('href')).toEqual(deployment.url);
      expect(el.querySelector('.js-deploy-meta').innerText).toContain(deployment.name);
      expect(el.querySelector('.js-deploy-url').getAttribute('href')).toEqual(deployment.external_url);
      expect(el.querySelector('.js-deploy-url').innerText).toContain(deployment.external_url_formatted);
      expect(el.querySelector('.js-deploy-time').innerText).toContain(vm.formatDate(deployment.deployed_at));
      expect(el.querySelector('.js-mr-memory-usage')).toBeDefined();
      expect(el.querySelector('button')).toBeDefined();
    });

    it('should list multiple deployments', (done) => {
      vm.mr.deployments.push(deployment);
      vm.mr.deployments.push(deployment);

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.ci-widget').length).toEqual(3);
        expect(el.querySelectorAll('.js-mr-memory-usage').length).toEqual(3);
        done();
      });
    });

    it('should not have some elements when there is not enough data', (done) => {
      vm.mr.deployments = [{}];

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.js-deploy-meta').length).toEqual(0);
        expect(el.querySelectorAll('.js-deploy-url').length).toEqual(0);
        expect(el.querySelectorAll('.js-deploy-time').length).toEqual(0);
        expect(el.querySelectorAll('.js-mr-memory-usage').length).toEqual(0);
        expect(el.querySelectorAll('.button').length).toEqual(0);
        done();
      });
    });
  });
});
