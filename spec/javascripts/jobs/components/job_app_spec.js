import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { waitForMutation } from 'spec/helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import jobApp from '~/jobs/components/job_app.vue';
import createStore from '~/jobs/store';
import * as types from '~/jobs/store/mutation_types';
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
    projectPath: 'user-name/project-name',
    subscriptionsMoreMinutesUrl: 'https://customers.gitlab.com/buy_pipeline_minutes',
    logState:
      'eyJvZmZzZXQiOjE3NDUxLCJuX29wZW5fdGFncyI6MCwiZmdfY29sb3IiOm51bGwsImJnX2NvbG9yIjpudWxsLCJzdHlsZV9tYXNrIjowfQ%3D%3D',
  };

  const waitForJobReceived = () => waitForMutation(store, types.RECEIVE_JOB_SUCCESS);
  const setupAndMount = ({ jobData = {}, traceData = {} } = {}) => {
    mock.onGet(props.endpoint).replyOnce(200, { ...job, ...jobData });
    mock.onGet(`${props.pagePath}/trace.json`).reply(200, traceData);

    vm = mountComponentWithStore(Component, { props, store });

    return waitForJobReceived();
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
      setupAndMount();
    });

    it('renders loading icon', () => {
      expect(vm.$el.querySelector('.js-job-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-job-sidebar')).toBeNull();
      expect(vm.$el.querySelector('.js-job-content')).toBeNull();
    });
  });

  describe('with successful request', () => {
    describe('Header section', () => {
      describe('job callout message', () => {
        it('should not render the reason when reason is absent', done => {
          setupAndMount()
            .then(() => {
              expect(vm.shouldRenderCalloutMessage).toBe(false);
            })
            .then(done)
            .catch(done.fail);
        });

        it('should render the reason when reason is present', done => {
          setupAndMount({
            jobData: {
              callout_message: 'There is an unkown failure, please try again',
            },
          })
            .then(() => {
              expect(vm.shouldRenderCalloutMessage).toBe(true);
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('triggered job', () => {
        beforeEach(done => {
          const aYearAgo = new Date();
          aYearAgo.setFullYear(aYearAgo.getFullYear() - 1);

          setupAndMount({ jobData: { started: aYearAgo.toISOString() } })
            .then(done)
            .catch(done.fail);
        });

        it('should render provided job information', () => {
          expect(
            vm.$el
              .querySelector('.header-main-content')
              .textContent.replace(/\s+/g, ' ')
              .trim(),
          ).toContain('passed Job #4757 triggered 1 year ago by Root');
        });

        it('should render new issue link', () => {
          expect(vm.$el.querySelector('.js-new-issue').getAttribute('href')).toEqual(
            job.new_issue_path,
          );
        });
      });

      describe('created job', () => {
        it('should render created key', done => {
          setupAndMount()
            .then(() => {
              expect(
                vm.$el
                  .querySelector('.header-main-content')
                  .textContent.replace(/\s+/g, ' ')
                  .trim(),
              ).toContain('passed Job #4757 created 3 weeks ago by Root');
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });

    describe('stuck block', () => {
      describe('without active runners availabl', () => {
        it('renders stuck block when there are no runners', done => {
          setupAndMount({
            jobData: {
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
            },
          })
            .then(() => {
              expect(vm.$el.querySelector('.js-job-stuck')).not.toBeNull();
              expect(
                vm.$el.querySelector('.js-job-stuck .js-stuck-no-active-runner'),
              ).not.toBeNull();
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('when available runners can not run specified tag', () => {
        it('renders tags in stuck block when there are no runners', done => {
          setupAndMount({
            jobData: {
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
            },
          })
            .then(() => {
              expect(vm.$el.querySelector('.js-job-stuck').textContent).toContain(job.tags[0]);
              expect(vm.$el.querySelector('.js-job-stuck .js-stuck-with-tags')).not.toBeNull();
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('when runners are offline and build has tags', () => {
        it('renders message about job being stuck because of no runners with the specified tags', done => {
          setupAndMount({
            jobData: {
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
            },
          })
            .then(() => {
              expect(vm.$el.querySelector('.js-job-stuck').textContent).toContain(job.tags[0]);
              expect(vm.$el.querySelector('.js-job-stuck .js-stuck-with-tags')).not.toBeNull();
            })
            .then(done)
            .catch(done.fail);
        });
      });

      it('does not renders stuck block when there are no runners', done => {
        setupAndMount({
          jobData: {
            runners: { available: true },
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-stuck')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('unmet prerequisites block', () => {
      it('renders unmet prerequisites block when there is an unmet prerequisites failure', done => {
        setupAndMount({
          jobData: {
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
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-failed')).not.toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('environments block', () => {
      it('renders environment block when job has environment', done => {
        setupAndMount({
          jobData: {
            deployment_status: {
              environment: {
                environment_path: '/path',
                name: 'foo',
              },
            },
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-environment')).not.toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not render environment block when job has environment', done => {
        setupAndMount()
          .then(() => {
            expect(vm.$el.querySelector('.js-job-environment')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('erased block', () => {
      it('renders erased block when `erased` is true', done => {
        setupAndMount({
          jobData: {
            erased_by: {
              username: 'root',
              web_url: 'gitlab.com/root',
            },
            erased_at: '2016-11-07T11:11:16.525Z',
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-erased-block')).not.toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not render erased block when `erased` is false', done => {
        setupAndMount({
          jobData: {
            erased_at: null,
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-erased-block')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('empty states block', () => {
      it('renders empty state when job does not have trace and is not running', done => {
        setupAndMount({
          jobData: {
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
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-empty-state')).not.toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not render empty state when job does not have trace but it is running', done => {
        setupAndMount({
          jobData: {
            has_trace: false,
            status: {
              group: 'running',
              icon: 'status_running',
              label: 'running',
              text: 'running',
              details_path: 'path',
            },
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not render empty state when job has trace but it is not running', done => {
        setupAndMount({ jobData: { has_trace: true } })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
        done();
      });

      it('displays remaining time for a delayed job', done => {
        const oneHourInMilliseconds = 3600000;
        spyOn(Date, 'now').and.callFake(
          () => new Date(delayedJobFixture.scheduled_at).getTime() - oneHourInMilliseconds,
        );
        setupAndMount({ jobData: delayedJobFixture })
          .then(() => {
            expect(vm.$el.querySelector('.js-job-empty-state')).not.toBeNull();

            const title = vm.$el.querySelector('.js-job-empty-state-title');

            expect(title).toContainText('01:00:00');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('sidebar', () => {
      it('has no blank blocks', done => {
        setupAndMount({
          jobData: {
            duration: null,
            finished_at: null,
            erased_at: null,
            queued: null,
            runner: null,
            coverage: null,
            tags: [],
            cancel_path: null,
          },
        })
          .then(() => {
            vm.$el.querySelectorAll('.blocks-container > *').forEach(block => {
              expect(block.textContent.trim()).not.toBe('');
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('archived job', () => {
    beforeEach(done => {
      setupAndMount({ jobData: { archived: true } })
        .then(done)
        .catch(done.fail);
    });

    it('renders warning about job being archived', () => {
      expect(vm.$el.querySelector('.js-archived-job ')).not.toBeNull();
    });
  });

  describe('non-archived job', () => {
    beforeEach(done => {
      setupAndMount()
        .then(done)
        .catch(done.fail);
    });

    it('does not warning about job being archived', () => {
      expect(vm.$el.querySelector('.js-archived-job ')).toBeNull();
    });
  });

  describe('trace output', () => {
    describe('with append flag', () => {
      it('appends the log content to the existing one', done => {
        setupAndMount({
          traceData: {
            html: '<span>More<span>',
            status: 'running',
            state: 'newstate',
            append: true,
            complete: true,
          },
        })
          .then(() => {
            vm.$store.state.trace = 'Update';

            return vm.$nextTick();
          })
          .then(() => {
            expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).toContain('Update');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('without append flag', () => {
      it('replaces the trace', done => {
        setupAndMount({
          traceData: {
            html: '<span>Different<span>',
            status: 'running',
            append: false,
            complete: true,
          },
        })
          .then(() => {
            expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).not.toContain(
              'Update',
            );

            expect(vm.$el.querySelector('.js-build-trace').textContent.trim()).toContain(
              'Different',
            );
          })
          .then(done)
          .catch(done.fail);
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

          setupAndMount({
            traceData: {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 50,
              total: 100,
              complete: true,
            },
          })
            .then(() => {
              expect(vm.$el.querySelector('.js-truncated-info').textContent.trim()).toContain(
                '50 bytes',
              );
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('when size is equal than total', () => {
        it('does not show the truncated information', done => {
          setupAndMount({
            traceData: {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 100,
              total: 100,
              complete: true,
            },
          })
            .then(() => {
              expect(vm.$el.querySelector('.js-truncated-info').textContent.trim()).not.toContain(
                '50 bytes',
              );
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });

    describe('trace controls', () => {
      beforeEach(done => {
        setupAndMount({
          traceData: {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
            complete: true,
          },
        })
          .then(done)
          .catch(done.fail);
      });

      it('should render scroll buttons', () => {
        expect(vm.$el.querySelector('.js-scroll-top')).not.toBeNull();
        expect(vm.$el.querySelector('.js-scroll-bottom')).not.toBeNull();
      });

      it('should render link to raw ouput', () => {
        expect(vm.$el.querySelector('.js-raw-link-controller')).not.toBeNull();
      });

      it('should render link to erase job', () => {
        expect(vm.$el.querySelector('.js-erase-link')).not.toBeNull();
      });
    });
  });
});
