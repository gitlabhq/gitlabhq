import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import jobApp from '~/jobs/components/job_app.vue';
import createStore from '~/jobs/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../store/helpers';
import job from '../mock_data';

describe('Job App ', () => {
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');
  const Component = Vue.extend(jobApp);
  let store;
  let vm;
  let mock;

  const props = {
    endpoint: `${gl.TEST_HOST}jobs/123.json`,
    runnerHelpUrl: 'help/runner',
    deploymentHelpUrl: 'help/deployment',
    runnerSettingsUrl: 'settings/ci-cd/runners',
    variablesSettingsUrl: 'settings/ci-cd/variables',
    terminalPath: 'jobs/123/terminal',
    pagePath: `${gl.TEST_HOST}jobs/123`,
    logState:
      'eyJvZmZzZXQiOjE3NDUxLCJuX29wZW5fdGFncyI6MCwiZmdfY29sb3IiOm51bGwsImJnX2NvbG9yIjpudWxsLCJzdHlsZV9tYXNrIjowfQ%3D%3D',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, job, {});
      mock.onGet(`${props.pagePath}/trace.json`).reply(200, {});
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders loading icon', done => {
      expect(vm.$el.querySelector('.js-job-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-job-sidebar')).toBeNull();
      expect(vm.$el.querySelector('.js-job-content')).toBeNull();

      setTimeout(() => {
        done();
      }, 0);
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      mock.onGet(`${props.pagePath}/trace.json`).replyOnce(200, {});
    });

    describe('Header section', () => {
      describe('job callout message', () => {
        it('should not render the reason when reason is absent', done => {
          mock.onGet(props.endpoint).replyOnce(200, job);
          vm = mountComponentWithStore(Component, { props, store });

          setTimeout(() => {
            expect(vm.shouldRenderCalloutMessage).toBe(false);

            done();
          }, 0);
        });

        it('should render the reason when reason is present', done => {
          mock.onGet(props.endpoint).replyOnce(
            200,
            Object.assign({}, job, {
              callout_message: 'There is an unknown failure, please try again',
            }),
          );

          vm = mountComponentWithStore(Component, { props, store });
          setTimeout(() => {
            expect(vm.shouldRenderCalloutMessage).toBe(true);
            done();
          }, 0);
        });
      });

      describe('triggered job', () => {
        beforeEach(() => {
          const aYearAgo = new Date();
          aYearAgo.setFullYear(aYearAgo.getFullYear() - 1);

          mock
            .onGet(props.endpoint)
            .replyOnce(200, Object.assign({}, job, { started: aYearAgo.toISOString() }));
          vm = mountComponentWithStore(Component, { props, store });
        });

        it('should render provided job information', done => {
          setTimeout(() => {
            expect(
              vm.$el
                .querySelector('.header-main-content')
                .textContent.replace(/\s+/g, ' ')
                .trim(),
            ).toContain('passed Job #4757 triggered 1 year ago by Root');
            done();
          }, 0);
        });

        it('should render new issue link', done => {
          setTimeout(() => {
            expect(vm.$el.querySelector('.js-new-issue').getAttribute('href')).toEqual(
              job.new_issue_path,
            );
            done();
          }, 0);
        });
      });

      describe('created job', () => {
        it('should render created key', done => {
          mock.onGet(props.endpoint).replyOnce(200, job);
          vm = mountComponentWithStore(Component, { props, store });

          setTimeout(() => {
            expect(
              vm.$el
                .querySelector('.header-main-content')
                .textContent.replace(/\s+/g, ' ')
                .trim(),
            ).toContain('passed Job #4757 created 3 weeks ago by Root');
            done();
          }, 0);
        });
      });
    });

    describe('stuck block', () => {
      describe('without active runners availabl', () => {
        it('renders stuck block when there are no runners', done => {
          mock.onGet(props.endpoint).replyOnce(
            200,
            Object.assign({}, job, {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: false,
                online: false,
              },
              tags: [],
            }),
          );
          vm = mountComponentWithStore(Component, { props, store });

          setTimeout(() => {
            expect(vm.$el.querySelector('.js-job-stuck')).not.toBeNull();
            expect(vm.$el.querySelector('.js-job-stuck .js-stuck-no-active-runner')).not.toBeNull();
            done();
          }, 0);
        });
      });

      describe('when available runners can not run specified tag', () => {
        it('renders tags in stuck block when there are no runners', done => {
          mock.onGet(props.endpoint).replyOnce(
            200,
            Object.assign({}, job, {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: false,
                online: false,
              },
            }),
          );

          vm = mountComponentWithStore(Component, {
            props,
            store,
          });

          setTimeout(() => {
            expect(vm.$el.querySelector('.js-job-stuck').textContent).toContain(job.tags[0]);
            expect(vm.$el.querySelector('.js-job-stuck .js-stuck-with-tags')).not.toBeNull();
            done();
          }, 0);
        });
      });

      describe('when runners are offline and build has tags', () => {
        it('renders message about job being stuck because of no runners with the specified tags', done => {
          mock.onGet(props.endpoint).replyOnce(
            200,
            Object.assign({}, job, {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: true,
                online: true,
              },
            }),
          );

          vm = mountComponentWithStore(Component, {
            props,
            store,
          });

          setTimeout(() => {
            expect(vm.$el.querySelector('.js-job-stuck').textContent).toContain(job.tags[0]);
            expect(vm.$el.querySelector('.js-job-stuck .js-stuck-with-tags')).not.toBeNull();
            done();
          }, 0);
        });
      });

      it('does not renders stuck block when there are no runners', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            runners: { available: true },
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-stuck')).toBeNull();

          done();
        }, 0);
      });
    });

    describe('unmet prerequisites block', () => {
      it('renders unmet prerequisites block when there is an unmet prerequisites failure', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            status: {
              group: 'failed',
              icon: 'status_failed',
              label: 'failed',
              text: 'failed',
              details_path: 'path',
              illustration: {
                content: 'Retry this job in order to create the necessary resources.',
                image: 'path',
                size: 'svg-430',
                title: 'Failed to create resources',
              },
            },
            failure_reason: 'unmet_prerequisites',
            has_trace: false,
            runners: {
              available: true,
            },
            tags: [],
          }),
        );
        vm = mountComponentWithStore(Component, { props, store });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-failed')).not.toBeNull();
          done();
        }, 0);
      });
    });

    describe('environments block', () => {
      it('renders environment block when job has environment', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            deployment_status: {
              environment: {
                environment_path: '/path',
                name: 'foo',
              },
            },
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-environment')).not.toBeNull();

          done();
        }, 0);
      });

      it('does not render environment block when job has environment', done => {
        mock.onGet(props.endpoint).replyOnce(200, job);

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-environment')).toBeNull();
          done();
        }, 0);
      });
    });

    describe('erased block', () => {
      it('renders erased block when `erased` is true', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            erased_by: {
              username: 'root',
              web_url: 'gitlab.com/root',
            },
            erased_at: '2016-11-07T11:11:16.525Z',
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-erased-block')).not.toBeNull();

          done();
        }, 0);
      });

      it('does not render erased block when `erased` is false', done => {
        mock.onGet(props.endpoint).replyOnce(200, Object.assign({}, job, { erased_at: null }));

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-erased-block')).toBeNull();

          done();
        }, 0);
      });
    });

    describe('empty states block', () => {
      it('renders empty state when job does not have trace and is not running', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            has_trace: false,
            status: {
              group: 'pending',
              icon: 'status_pending',
              label: 'pending',
              text: 'pending',
              details_path: 'path',
              illustration: {
                image: 'path',
                size: '340',
                title: 'Empty State',
                content: 'This is an empty state',
              },
              action: {
                button_title: 'Retry job',
                method: 'post',
                path: '/path',
              },
            },
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-empty-state')).not.toBeNull();

          done();
        }, 0);
      });

      it('does not render empty state when job does not have trace but it is running', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            has_trace: false,
            status: {
              group: 'running',
              icon: 'status_running',
              label: 'running',
              text: 'running',
              details_path: 'path',
            },
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();

          done();
        }, 0);
      });

      it('does not render empty state when job has trace but it is not running', done => {
        mock.onGet(props.endpoint).replyOnce(200, Object.assign({}, job, { has_trace: true }));

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();

          done();
        }, 0);
      });

      it('displays remaining time for a delayed job', done => {
        const oneHourInMilliseconds = 3600000;
        spyOn(Date, 'now').and.callFake(
          () => new Date(delayedJobFixture.scheduled_at).getTime() - oneHourInMilliseconds,
        );
        mock.onGet(props.endpoint).replyOnce(200, { ...delayedJobFixture });

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        store.subscribeAction(action => {
          if (action.type !== 'receiveJobSuccess') {
            return;
          }

          Vue.nextTick()
            .then(() => {
              expect(vm.$el.querySelector('.js-job-empty-state')).not.toBeNull();

              const title = vm.$el.querySelector('.js-job-empty-state-title');

              expect(title).toContainText('01:00:00');
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('sidebar', () => {
      it('has no blank blocks', done => {
        mock.onGet(props.endpoint).replyOnce(
          200,
          Object.assign({}, job, {
            duration: null,
            finished_at: null,
            erased_at: null,
            queued: null,
            runner: null,
            coverage: null,
            tags: [],
            cancel_path: null,
          }),
        );

        vm.$nextTick(() => {
          vm.$el.querySelectorAll('.blocks-container > *').forEach(block => {
            expect(block.textContent.trim()).not.toBe('');
          });
          done();
        });
      });
    });
  });

  describe('archived job', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, Object.assign({}, job, { archived: true }), {});
      vm = mountComponentWithStore(Component, {
        props,
        store,
      });
    });

    it('renders warning about job being archived', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-archived-job ')).not.toBeNull();
        done();
      }, 0);
    });
  });

  describe('non-archived job', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, job, {});
      vm = mountComponentWithStore(Component, {
        props,
        store,
      });
    });

    it('does not warning about job being archived', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-archived-job ')).toBeNull();
        done();
      }, 0);
    });
  });

  describe('trace output', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, job, {});
    });

    describe('with append flag', () => {
      it('appends the log content to the existing one', done => {
        mock.onGet(`${props.pagePath}/trace.json`).reply(200, {
          html: '<span>More<span>',
          status: 'running',
          state: 'newstate',
          append: true,
          complete: true,
        });

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        vm.$store.state.trace = 'Update';

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).toContain('Update');

          done();
        }, 0);
      });
    });

    describe('without append flag', () => {
      it('replaces the trace', done => {
        mock.onGet(`${props.pagePath}/trace.json`).reply(200, {
          html: '<span>Different<span>',
          status: 'running',
          append: false,
          complete: true,
        });

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });
        vm.$store.state.trace = 'Update';

        setTimeout(() => {
          expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).not.toContain(
            'Update',
          );

          expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).toContain('Different');
          done();
        }, 0);
      });
    });

    describe('truncated information', () => {
      describe('when size is less than total', () => {
        it('shows information about truncated log', done => {
          mock.onGet(`${props.pagePath}/trace.json`).reply(200, {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
            complete: true,
          });

          vm = mountComponentWithStore(Component, {
            props,
            store,
          });

          setTimeout(() => {
            expect(vm.$el.querySelector('.js-truncated-info').textContent.trim()).toContain(
              '50 bytes',
            );
            done();
          }, 0);
        });
      });

      describe('when size is equal than total', () => {
        it('does not show the truncated information', done => {
          mock.onGet(`${props.pagePath}/trace.json`).reply(200, {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 100,
            total: 100,
            complete: true,
          });

          vm = mountComponentWithStore(Component, {
            props,
            store,
          });

          setTimeout(() => {
            expect(vm.$el.querySelector('.js-truncated-info').textContent.trim()).not.toContain(
              '50 bytes',
            );
            done();
          }, 0);
        });
      });
    });

    describe('trace controls', () => {
      beforeEach(() => {
        mock.onGet(`${props.pagePath}/trace.json`).reply(200, {
          html: '<span>Update</span>',
          status: 'success',
          append: false,
          size: 50,
          total: 100,
          complete: true,
        });

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });
      });

      it('should render scroll buttons', done => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-scroll-top')).not.toBeNull();
          expect(vm.$el.querySelector('.js-scroll-bottom')).not.toBeNull();
          done();
        }, 0);
      });

      it('should render link to raw ouput', done => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-raw-link-controller')).not.toBeNull();
          done();
        }, 0);
      });

      it('should render link to erase job', done => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-erase-link')).not.toBeNull();
          done();
        }, 0);
      });
    });
  });
});
