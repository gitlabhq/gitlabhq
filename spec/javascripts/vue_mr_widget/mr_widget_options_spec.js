import Vue from 'vue';
import mrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import notify from '~/lib/utils/notify';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from './mock_data';
import { faviconDataUrl, overlayDataUrl } from '../lib/utils/mock_data';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';

const returnPromise = data =>
  new Promise(resolve => {
    resolve({
      data,
    });
  });

describe('mrWidgetOptions', () => {
  let vm;
  let MrWidgetOptions;

  const COLLABORATION_MESSAGE = 'Allows commits from members who can merge to the target branch';

  beforeEach(() => {
    // Prevent component mounting
    delete mrWidgetOptions.el;

    MrWidgetOptions = Vue.extend(mrWidgetOptions);
    vm = mountComponent(MrWidgetOptions, {
      mrData: { ...mockData },
    });
  });

  afterEach(() => {
    vm.$destroy();
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

    describe('shouldRenderCollaborationStatus', () => {
      describe('when collaboration is allowed', () => {
        beforeEach(() => {
          vm.mr.allowCollaboration = true;
        });

        describe('when merge request is opened', () => {
          beforeEach(done => {
            vm.mr.isOpen = true;
            vm.$nextTick(done);
          });

          it('should render collaboration status', () => {
            expect(vm.$el.textContent).toContain(COLLABORATION_MESSAGE);
          });
        });

        describe('when merge request is not opened', () => {
          beforeEach(done => {
            vm.mr.isOpen = false;
            vm.$nextTick(done);
          });

          it('should not render collaboration status', () => {
            expect(vm.$el.textContent).not.toContain(COLLABORATION_MESSAGE);
          });
        });
      });

      describe('when collaboration is not allowed', () => {
        beforeEach(() => {
          vm.mr.allowCollaboration = false;
        });

        describe('when merge request is opened', () => {
          beforeEach(done => {
            vm.mr.isOpen = true;
            vm.$nextTick(done);
          });

          it('should not render collaboration status', () => {
            expect(vm.$el.textContent).not.toContain(COLLABORATION_MESSAGE);
          });
        });
      });
    });

    describe('showMergePipelineForkWarning', () => {
      describe('when the source project and target project are the same', () => {
        beforeEach(done => {
          Vue.set(vm.mr, 'mergePipelinesEnabled', true);
          Vue.set(vm.mr, 'sourceProjectId', 1);
          Vue.set(vm.mr, 'targetProjectId', 1);
          vm.$nextTick(done);
        });

        it('should be false', () => {
          expect(vm.showMergePipelineForkWarning).toEqual(false);
        });
      });

      describe('when merge pipelines are not enabled', () => {
        beforeEach(done => {
          Vue.set(vm.mr, 'mergePipelinesEnabled', false);
          Vue.set(vm.mr, 'sourceProjectId', 1);
          Vue.set(vm.mr, 'targetProjectId', 2);
          vm.$nextTick(done);
        });

        it('should be false', () => {
          expect(vm.showMergePipelineForkWarning).toEqual(false);
        });
      });

      describe('when merge pipelines are enabled _and_ the source project and target project are different', () => {
        beforeEach(done => {
          Vue.set(vm.mr, 'mergePipelinesEnabled', true);
          Vue.set(vm.mr, 'sourceProjectId', 1);
          Vue.set(vm.mr, 'targetProjectId', 2);
          vm.$nextTick(done);
        });

        it('should be true', () => {
          expect(vm.showMergePipelineForkWarning).toEqual(true);
        });
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
        spyOn(vm.service, 'fetchDeployments').and.returnValue(
          returnPromise([{ id: 1, status: SUCCESS }]),
        );

        vm.fetchPreMergeDeployments();

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

    describe('setFavicon', () => {
      let faviconElement;

      beforeEach(() => {
        const favicon = document.createElement('link');
        favicon.setAttribute('id', 'favicon');
        favicon.setAttribute('data-original-href', faviconDataUrl);
        document.body.appendChild(favicon);

        faviconElement = document.getElementById('favicon');
      });

      afterEach(() => {
        document.body.removeChild(document.getElementById('favicon'));
      });

      it('should call setFavicon method', done => {
        vm.mr.ciStatusFaviconPath = overlayDataUrl;
        vm.setFaviconHelper()
          .then(() => {
            /*
            It would be better if we'd could mock commonUtils.setFaviconURL
            with a spy and test that it was called. We are doing the following
            tests as a proxy to show that the function has been called
            */
            expect(faviconElement.getAttribute('href')).not.toEqual(null);
            expect(faviconElement.getAttribute('href')).not.toEqual(overlayDataUrl);
            expect(faviconElement.getAttribute('href')).not.toEqual(faviconDataUrl);
            done();
          })
          .catch(done.fail);
      });

      it('should not call setFavicon when there is no ciStatusFaviconPath', done => {
        vm.mr.ciStatusFaviconPath = null;
        vm.setFaviconHelper()
          .then(() => {
            expect(faviconElement.getAttribute('href')).toEqual(null);
            done();
          })
          .catch(done.fail);
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
          <a class="close-related-link" href="#">
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

        expect(vm.$el.textContent).toContain('Deletes source branch');
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
        expect(vm.$el.textContent).toContain('The source branch has been deleted');
        expect(vm.$el.textContent).not.toContain('Deletes source branch');

        done();
      });
    });
  });

  describe('rendering deployments', () => {
    const changes = [
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
    ];
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
      changes,
      status: SUCCESS,
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

    it('renders dropdpown with multiple file changes', () => {
      expect(
        vm.$el
          .querySelector('.js-mr-wigdet-deployment-dropdown')
          .querySelectorAll('.js-filtered-dropdown-result').length,
      ).toEqual(changes.length);
    });
  });

  describe('pipeline for target branch after merge', () => {
    describe('with information for target branch pipeline', () => {
      beforeEach(done => {
        vm.mr.state = 'merged';
        vm.mr.mergePipeline = {
          id: 127,
          user: {
            id: 1,
            name: 'Administrator',
            username: 'root',
            state: 'active',
            avatar_url: null,
            web_url: 'http://localhost:3000/root',
            status_tooltip_html: null,
            path: '/root',
          },
          active: true,
          coverage: null,
          source: 'push',
          created_at: '2018-10-22T11:41:35.186Z',
          updated_at: '2018-10-22T11:41:35.433Z',
          path: '/root/ci-web-terminal/pipelines/127',
          flags: {
            latest: true,
            stuck: true,
            auto_devops: false,
            yaml_errors: false,
            retryable: false,
            cancelable: true,
            failure_reason: false,
          },
          details: {
            status: {
              icon: 'status_pending',
              text: 'pending',
              label: 'pending',
              group: 'pending',
              tooltip: 'pending',
              has_details: true,
              details_path: '/root/ci-web-terminal/pipelines/127',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
            },
            duration: null,
            finished_at: null,
            stages: [
              {
                name: 'test',
                title: 'test: pending',
                status: {
                  icon: 'status_pending',
                  text: 'pending',
                  label: 'pending',
                  group: 'pending',
                  tooltip: 'pending',
                  has_details: true,
                  details_path: '/root/ci-web-terminal/pipelines/127#test',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
                },
                path: '/root/ci-web-terminal/pipelines/127#test',
                dropdown_path: '/root/ci-web-terminal/pipelines/127/stage.json?stage=test',
              },
            ],
            artifacts: [],
            manual_actions: [],
            scheduled_actions: [],
          },
          ref: {
            name: 'master',
            path: '/root/ci-web-terminal/commits/master',
            tag: false,
            branch: true,
          },
          commit: {
            id: 'aa1939133d373c94879becb79d91828a892ee319',
            short_id: 'aa193913',
            title: "Merge branch 'master-test' into 'master'",
            created_at: '2018-10-22T11:41:33.000Z',
            parent_ids: [
              '4622f4dd792468993003caf2e3be978798cbe096',
              '76598df914cdfe87132d0c3c40f80db9fa9396a4',
            ],
            message:
              "Merge branch 'master-test' into 'master'\n\nUpdate .gitlab-ci.yml\n\nSee merge request root/ci-web-terminal!1",
            author_name: 'Administrator',
            author_email: 'admin@example.com',
            authored_date: '2018-10-22T11:41:33.000Z',
            committer_name: 'Administrator',
            committer_email: 'admin@example.com',
            committed_date: '2018-10-22T11:41:33.000Z',
            author: {
              id: 1,
              name: 'Administrator',
              username: 'root',
              state: 'active',
              avatar_url: null,
              web_url: 'http://localhost:3000/root',
              status_tooltip_html: null,
              path: '/root',
            },
            author_gravatar_url: null,
            commit_url:
              'http://localhost:3000/root/ci-web-terminal/commit/aa1939133d373c94879becb79d91828a892ee319',
            commit_path: '/root/ci-web-terminal/commit/aa1939133d373c94879becb79d91828a892ee319',
          },
          cancel_path: '/root/ci-web-terminal/pipelines/127/cancel',
        };
        vm.$nextTick(done);
      });

      it('renders pipeline block', () => {
        expect(vm.$el.querySelector('.js-post-merge-pipeline')).not.toBeNull();
      });

      describe('with post merge deployments', () => {
        beforeEach(done => {
          vm.mr.postMergeDeployments = [
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
              changes: [
                {
                  path: 'index.html',
                  external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/index.html',
                },
                {
                  path: 'imgs/gallery.html',
                  external_url:
                    'http://root-master-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
                },
                {
                  path: 'about/',
                  external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/about/',
                },
              ],
              status: 'success',
            },
          ];

          vm.$nextTick(done);
        });

        it('renders post deployment information', () => {
          expect(vm.$el.querySelector('.js-post-deployment')).not.toBeNull();
        });
      });
    });

    describe('without information for target branch pipeline', () => {
      beforeEach(done => {
        vm.mr.state = 'merged';

        vm.$nextTick(done);
      });

      it('does not render pipeline block', () => {
        expect(vm.$el.querySelector('.js-post-merge-pipeline')).toBeNull();
      });
    });

    describe('when state is not merged', () => {
      beforeEach(done => {
        vm.mr.state = 'archived';

        vm.$nextTick(done);
      });

      it('does not render pipeline block', () => {
        expect(vm.$el.querySelector('.js-post-merge-pipeline')).toBeNull();
      });

      it('does not render post deployment information', () => {
        expect(vm.$el.querySelector('.js-post-deployment')).toBeNull();
      });
    });
  });
});
