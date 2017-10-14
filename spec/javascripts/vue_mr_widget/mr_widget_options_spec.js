import Vue from 'vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import mrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import eventHub from '~/vue_merge_request_widget/event_hub';
import notify from '~/lib/utils/notify';
import mockData from './mock_data';

const createComponent = () => {
  delete mrWidgetOptions.el; // Prevent component mounting
  gl.mrWidgetData = mockData;
  const Component = Vue.extend(mrWidgetOptions);
  return new Component();
};

const returnPromise = data => new Promise((resolve) => {
  resolve({
    json() {
      return data;
    },
    body: data,
  });
});

describe('mrWidgetOptions', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
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
        vm.mr.relatedLinks = {};
        expect(vm.shouldRenderRelatedLinks).toBeTruthy();
      });
    });

    describe('shouldRenderDeployments', () => {
      it('should return false for the initial data', () => {
        expect(vm.shouldRenderDeployments).toBeFalsy();
      });

      it('should return true if there is deployments', () => {
        vm.mr.deployments.push({}, {});
        expect(vm.shouldRenderDeployments).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('checkStatus', () => {
      it('should tell service to check status', (done) => {
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
        spyOn(gl, 'SmartInterval').and.returnValue({
          resume() {},
          stopTimer() {},
        });
        vm.initPolling();

        expect(vm.pollingInterval).toBeDefined();
        expect(gl.SmartInterval).toHaveBeenCalled();
      });
    });

    describe('initDeploymentsPolling', () => {
      it('should call SmartInterval', () => {
        spyOn(gl, 'SmartInterval');
        vm.initDeploymentsPolling();

        expect(vm.deploymentsInterval).toBeDefined();
        expect(gl.SmartInterval).toHaveBeenCalled();
      });
    });

    describe('fetchDeployments', () => {
      it('should fetch deployments', (done) => {
        spyOn(vm.service, 'fetchDeployments').and.returnValue(returnPromise([{ deployment: 1 }]));

        vm.fetchDeployments();

        setTimeout(() => {
          expect(vm.service.fetchDeployments).toHaveBeenCalled();
          expect(vm.mr.deployments.length).toEqual(1);
          expect(vm.mr.deployments[0].deployment).toEqual(1);
          done();
        }, 333);
      });
    });

    describe('fetchActionsContent', () => {
      it('should fetch content of Cherry Pick and Revert modals', (done) => {
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
        allArgs.forEach((params) => {
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
        spyOn(vm, 'setFavicon');

        vm.handleMounted();

        expect(vm.setFavicon).toHaveBeenCalled();
        expect(vm.initDeploymentsPolling).toHaveBeenCalled();
      });
    });

    describe('setFavicon', () => {
      it('should call setFavicon method', () => {
        spyOn(gl.utils, 'setFavicon');
        vm.setFavicon();

        expect(gl.utils.setFavicon).toHaveBeenCalledWith(vm.mr.ciStatusFaviconPath);
      });

      it('should not call setFavicon when there is no ciStatusFaviconPath', () => {
        spyOn(gl.utils, 'setFavicon');
        vm.mr.ciStatusFaviconPath = null;
        vm.setFavicon();

        expect(gl.utils.setFavicon).not.toHaveBeenCalled();
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

    describe('createService', () => {
      it('should instantiate a Service', () => {
        const endpoints = {
          mergePath: '/nice/path',
          mergeCheckPath: '/nice/path',
          cancelAutoMergePath: '/nice/path',
          removeWIPPath: '/nice/path',
          sourceBranchPath: '/nice/path',
          ciEnvironmentsStatusPath: '/nice/path',
          statusPath: '/nice/path',
          mergeActionsContentPath: '/nice/path',
        };

        const serviceInstance = vm.createService(endpoints);
        const isInstanceOfMRService = serviceInstance instanceof MRWidgetService;
        expect(isInstanceOfMRService).toBe(true);
        Object.keys(serviceInstance).forEach((key) => {
          expect(serviceInstance[key]).toBeDefined();
        });
      });
    });
  });

  describe('components', () => {
    it('should register all components', () => {
      const comps = mrWidgetOptions.components;
      expect(comps['mr-widget-header']).toBeDefined();
      expect(comps['mr-widget-merge-help']).toBeDefined();
      expect(comps['mr-widget-pipeline']).toBeDefined();
      expect(comps['mr-widget-deployment']).toBeDefined();
      expect(comps['mr-widget-related-links']).toBeDefined();
      expect(comps['mr-widget-merged']).toBeDefined();
      expect(comps['mr-widget-closed']).toBeDefined();
      expect(comps['mr-widget-merging']).toBeDefined();
      expect(comps['mr-widget-failed-to-merge']).toBeDefined();
      expect(comps['mr-widget-wip']).toBeDefined();
      expect(comps['mr-widget-archived']).toBeDefined();
      expect(comps['mr-widget-conflicts']).toBeDefined();
      expect(comps['mr-widget-nothing-to-merge']).toBeDefined();
      expect(comps['mr-widget-not-allowed']).toBeDefined();
      expect(comps['mr-widget-missing-branch']).toBeDefined();
      expect(comps['mr-widget-ready-to-merge']).toBeDefined();
      expect(comps['mr-widget-checking']).toBeDefined();
      expect(comps['mr-widget-unresolved-discussions']).toBeDefined();
      expect(comps['mr-widget-pipeline-blocked']).toBeDefined();
      expect(comps['mr-widget-pipeline-failed']).toBeDefined();
      expect(comps['mr-widget-merge-when-pipeline-succeeds']).toBeDefined();
    });
  });
});
