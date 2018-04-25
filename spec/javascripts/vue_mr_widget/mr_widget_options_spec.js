import Vue from 'vue';
import mrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import eventHub from '~/vue_merge_request_widget/event_hub';
import notify from '~/lib/utils/notify';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from './mock_data';

const returnPromise = data =>
  new Promise(resolve => {
    resolve({
      data,
    });
  });

describe('mrWidgetOptions', () => {
  let vm;
  let MrWidgetOptions;

  beforeEach(() => {
    // Prevent component mounting
    delete mrWidgetOptions.el;

    MrWidgetOptions = Vue.extend(mrWidgetOptions);
    vm = mountComponent(MrWidgetOptions, {
      mrData: { ...mockData },
    });
  });

  describe('data', () => {
    it('should instantiate Store and Service', () => {
      expect(vm.mr).toBeDefined();
      expect(vm.service).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('componentName', () => {
      it('should return merged component', () => {
        expect(vm.componentName).toEqual('mr-widget-merged');
      });

      it('should return conflicts component', () => {
        vm.mr.state = 'conflicts';
        expect(vm.componentName).toEqual('mr-widget-conflicts');
      });
    });

    describe('shouldRenderMergeHelp', () => {
      it('should return false for the initial merged state', () => {
        expect(vm.shouldRenderMergeHelp).toBeFalsy();
      });

      it('should return true for a state which requires help widget', () => {
        vm.mr.state = 'conflicts';
        expect(vm.shouldRenderMergeHelp).toBeTruthy();
      });
    });

    describe('shouldRenderPipelines', () => {
      it('should return true when hasCI is true', () => {
        vm.mr.hasCI = true;

        expect(vm.shouldRenderPipelines).toBeTruthy();
      });

      it('should return false when hasCI is false', () => {
        vm.mr.hasCI = false;

        expect(vm.shouldRenderPipelines).toBeFalsy();
      });
    });

    describe('shouldRenderRelatedLinks', () => {
      it('should return false for the initial data', () => {
        expect(vm.shouldRenderRelatedLinks).toBeFalsy();
      });

      it('should return true if there is relatedLinks in MR', () => {
        Vue.set(vm.mr, 'relatedLinks', {});
        expect(vm.shouldRenderRelatedLinks).toBeTruthy();
      });
    });

    describe('shouldRenderSourceBranchRemovalStatus', () => {
      beforeEach(() => {
        vm.mr.state = 'readyToMerge';
      });

      it('should return true when cannot remove source branch and branch will be removed', () => {
        vm.mr.canRemoveSourceBranch = false;
        vm.mr.shouldRemoveSourceBranch = true;

        expect(vm.shouldRenderSourceBranchRemovalStatus).toEqual(true);
      });

      it('should return false when can remove source branch and branch will be removed', () => {
        vm.mr.canRemoveSourceBranch = true;
        vm.mr.shouldRemoveSourceBranch = true;

        expect(vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
      });

      it('should return false when cannot remove source branch and branch will not be removed', () => {
        vm.mr.canRemoveSourceBranch = false;
        vm.mr.shouldRemoveSourceBranch = false;

        expect(vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
      });

      it('should return false when in merged state', () => {
        vm.mr.canRemoveSourceBranch = false;
        vm.mr.shouldRemoveSourceBranch = true;
        vm.mr.state = 'merged';

        expect(vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
      });

      it('should return false when in nothing to merge state', () => {
        vm.mr.canRemoveSourceBranch = false;
        vm.mr.shouldRemoveSourceBranch = true;
        vm.mr.state = 'nothingToMerge';

        expect(vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
      });
    });
  });

  describe('methods', () => {
    describe('checkStatus', () => {
      it('should tell service to check status', done => {
        spyOn(vm.service, 'checkStatus').and.returnValue(returnPromise(mockData));
        spyOn(vm.mr, 'setData');
        spyOn(vm, 'handleNotification');

        let isCbExecuted = false;
        const cb = () => {
          isCbExecuted = true;
        };

        vm.checkStatus(cb);

        setTimeout(() => {
          expect(vm.service.checkStatus).toHaveBeenCalled();
          expect(vm.mr.setData).toHaveBeenCalled();
          expect(vm.handleNotification).toHaveBeenCalledWith(mockData);
          expect(isCbExecuted).toBeTruthy();
          done();
        }, 333);
      });
    });

    describe('initPolling', () => {
      it('should call SmartInterval', () => {
        spyOn(vm, 'checkStatus').and.returnValue(Promise.resolve());
        jasmine.clock().install();
        vm.initPolling();

        expect(vm.checkStatus).not.toHaveBeenCalled();

        jasmine.clock().tick(10000);

        expect(vm.pollingInterval).toBeDefined();
        expect(vm.checkStatus).toHaveBeenCalled();

        jasmine.clock().uninstall();
      });
    });

    describe('initDeploymentsPolling', () => {
      it('should call SmartInterval', () => {
        spyOn(vm, 'fetchDeployments').and.returnValue(Promise.resolve());
        vm.initDeploymentsPolling();

        expect(vm.deploymentsInterval).toBeDefined();
        expect(vm.fetchDeployments).toHaveBeenCalled();
      });
    });

    describe('fetchDeployments', () => {
      it('should fetch deployments', done => {
        spyOn(vm.service, 'fetchDeployments').and.returnValue(returnPromise([{ id: 1 }]));

        vm.fetchDeployments();

        setTimeout(() => {
          expect(vm.service.fetchDeployments).toHaveBeenCalled();
          expect(vm.mr.deployments.length).toEqual(1);
          expect(vm.mr.deployments[0].id).toBe(1);
          done();
        });
      });
    });

    describe('fetchActionsContent', () => {
      it('should fetch content of Cherry Pick and Revert modals', done => {
        spyOn(vm.service, 'fetchMergeActionsContent').and.returnValue(returnPromise('hello world'));

        vm.fetchActionsContent();

        setTimeout(() => {
          expect(vm.service.fetchMergeActionsContent).toHaveBeenCalled();
          expect(document.body.textContent).toContain('hello world');
          done();
        }, 333);
      });
    });

    describe('bindEventHubListeners', () => {
      it('should bind eventHub listeners', () => {
        spyOn(vm, 'checkStatus').and.returnValue(() => {});
        spyOn(vm.service, 'checkStatus').and.returnValue(returnPromise(mockData));
        spyOn(vm, 'fetchActionsContent');
        spyOn(vm.mr, 'setData');
        spyOn(vm, 'resumePolling');
        spyOn(vm, 'stopPolling');
        spyOn(eventHub, '$on');

        vm.bindEventHubListeners();

        eventHub.$emit('SetBranchRemoveFlag', ['flag']);
        expect(vm.mr.isRemovingSourceBranch).toEqual('flag');

        eventHub.$emit('FailedToMerge');
        expect(vm.mr.state).toEqual('failedToMerge');

        eventHub.$emit('UpdateWidgetData', mockData);
        expect(vm.mr.setData).toHaveBeenCalledWith(mockData);

        eventHub.$emit('EnablePolling');
        expect(vm.resumePolling).toHaveBeenCalled();

        eventHub.$emit('DisablePolling');
        expect(vm.stopPolling).toHaveBeenCalled();

        const listenersWithServiceRequest = {
          MRWidgetUpdateRequested: true,
          FetchActionsContent: true,
        };

        const allArgs = eventHub.$on.calls.allArgs();
        allArgs.forEach(params => {
          const eventName = params[0];
          const callback = params[1];

          if (listenersWithServiceRequest[eventName]) {
            listenersWithServiceRequest[eventName] = callback;
          }
        });

        listenersWithServiceRequest.MRWidgetUpdateRequested();
        expect(vm.checkStatus).toHaveBeenCalled();

        listenersWithServiceRequest.FetchActionsContent();
        expect(vm.fetchActionsContent).toHaveBeenCalled();
      });
    });

    describe('handleMounted', () => {
      it('should call required methods to do the initial kick-off', () => {
        spyOn(vm, 'initDeploymentsPolling');
        spyOn(vm, 'setFaviconHelper');

        vm.handleMounted();

        expect(vm.setFaviconHelper).toHaveBeenCalled();
        expect(vm.initDeploymentsPolling).toHaveBeenCalled();
      });
    });

    describe('setFavicon', () => {
      let faviconElement;

      beforeEach(() => {
        const favicon = document.createElement('link');
        favicon.setAttribute('id', 'favicon');
        document.body.appendChild(favicon);

        faviconElement = document.getElementById('favicon');
      });

      afterEach(() => {
        document.body.removeChild(document.getElementById('favicon'));
      });

      it('should call setFavicon method', () => {
        vm.setFaviconHelper();

        expect(faviconElement.getAttribute('href')).toEqual(vm.mr.ciStatusFaviconPath);
      });

      it('should not call setFavicon when there is no ciStatusFaviconPath', () => {
        vm.mr.ciStatusFaviconPath = null;
        vm.setFaviconHelper();

        expect(faviconElement.getAttribute('href')).toEqual(null);
      });
    });

    describe('handleNotification', () => {
      const data = {
        ci_status: 'running',
        title: 'title',
        pipeline: { details: { status: { label: 'running-label' } } },
      };

      beforeEach(() => {
        spyOn(notify, 'notifyMe');

        vm.mr.ciStatus = 'failed';
        vm.mr.gitlabLogo = 'logo.png';
      });

      it('should call notifyMe', () => {
        vm.handleNotification(data);

        expect(notify.notifyMe).toHaveBeenCalledWith(
          'Pipeline running-label',
          'Pipeline running-label for "title"',
          'logo.png',
        );
      });

      it('should not call notifyMe if the status has not changed', () => {
        vm.mr.ciStatus = data.ci_status;

        vm.handleNotification(data);

        expect(notify.notifyMe).not.toHaveBeenCalled();
      });

      it('should not notify if no pipeline provided', () => {
        vm.handleNotification({
          ...data,
          pipeline: undefined,
        });

        expect(notify.notifyMe).not.toHaveBeenCalled();
      });
    });

    describe('resumePolling', () => {
      it('should call stopTimer on pollingInterval', () => {
        spyOn(vm.pollingInterval, 'resume');

        vm.resumePolling();
        expect(vm.pollingInterval.resume).toHaveBeenCalled();
      });
    });

    describe('stopPolling', () => {
      it('should call stopTimer on pollingInterval', () => {
        spyOn(vm.pollingInterval, 'stopTimer');

        vm.stopPolling();
        expect(vm.pollingInterval.stopTimer).toHaveBeenCalled();
      });
    });
  });

  describe('rendering relatedLinks', () => {
    beforeEach(done => {
      vm.mr.relatedLinks = {
        assignToMe: null,
        closing: `
          <a class="close-related-link" href="#'>
            Close
          </a>
        `,
        mentioned: '',
      };
      Vue.nextTick(done);
    });

    it('renders if there are relatedLinks', () => {
      expect(vm.$el.querySelector('.close-related-link')).toBeDefined();
    });

    it('does not render if state is nothingToMerge', done => {
      vm.mr.state = stateKey.nothingToMerge;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.close-related-link')).toBeNull();
        done();
      });
    });
  });

  describe('rendering source branch removal status', () => {
    it('renders when user cannot remove branch and branch should be removed', done => {
      vm.mr.canRemoveSourceBranch = false;
      vm.mr.shouldRemoveSourceBranch = true;
      vm.mr.state = 'readyToMerge';

      vm.$nextTick(() => {
        const tooltip = vm.$el.querySelector('.fa-question-circle');

        expect(vm.$el.textContent).toContain('Removes source branch');
        expect(tooltip.getAttribute('data-original-title')).toBe(
          'A user with write access to the source branch selected this option',
        );

        done();
      });
    });

    it('does not render in merged state', done => {
      vm.mr.canRemoveSourceBranch = false;
      vm.mr.shouldRemoveSourceBranch = true;
      vm.mr.state = 'merged';

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain('The source branch has been removed');
        expect(vm.$el.textContent).not.toContain('Removes source branch');

        done();
      });
    });
  });

  describe('rendering deployments', () => {
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

    beforeEach(done => {
      vm.mr.deployments.push(
        {
          ...deploymentMockData,
        },
        {
          ...deploymentMockData,
          id: deploymentMockData.id + 1,
        },
      );

      vm.$nextTick(done);
    });

    it('renders multiple deployments', () => {
      expect(vm.$el.querySelectorAll('.deploy-heading').length).toBe(2);
    });
  });
});
