import Vue from 'vue';
import deploymentStopComponent from '~/vue_merge_request_widget/components/deployment/deployment_stop_button.vue';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Deployment component', () => {
  const Component = Vue.extend(deploymentStopComponent);
  let deploymentMockData;

  beforeEach(() => {
    deploymentMockData = {
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
      deployment_manual_actions: [],
      status: SUCCESS,
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
  });

  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        stopUrl: deploymentMockData.stop_url,
        isDeployInProgress: false,
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
        const visitUrl = spyOnDependency(deploymentStopComponent, 'visitUrl').and.returnValue(true);
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
});
