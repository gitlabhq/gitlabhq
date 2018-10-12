import Vue from 'vue';
import jobApp from '~/jobs/components/job_app.vue';
import createStore from '~/jobs/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Job App ', () => {
  const Component = Vue.extend(jobApp);
  let store;
  let vm;

  const threeWeeksAgo = new Date();
  threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

  const twoDaysAgo = new Date();
  twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

  const job = {
    status: {
      group: 'failed',
      icon: 'status_failed',
      label: 'failed',
      text: 'failed',
      details_path: 'path',
    },
    id: 123,
    created_at: threeWeeksAgo.toISOString(),
    user: {
      web_url: 'path',
      name: 'Foo',
      username: 'foobar',
      email: 'foo@bar.com',
      avatar_url: 'link',
    },
    started: twoDaysAgo.toISOString(),
    new_issue_path: 'path',
    runners: {
      available: false,
    },
    tags: ['docker'],
    has_trace: true,
  };

  const props = {
    runnerSettingsUrl: 'settings/ci-cd/runners',
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Header section', () => {
    describe('job callout message', () => {
      it('should not render the reason when reason is absent', () => {
        store.dispatch('receiveJobSuccess', job);

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        expect(vm.shouldRenderCalloutMessage).toBe(false);
      });

      it('should render the reason when reason is present', () => {
        store.dispatch(
          'receiveJobSuccess',
          Object.assign({}, job, {
            callout_message: 'There is an unknown failure, please try again',
          }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        expect(vm.shouldRenderCalloutMessage).toBe(true);
      });
    });

    describe('triggered job', () => {
      beforeEach(() => {
        store.dispatch('receiveJobSuccess', job);

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });
      });

      it('should render provided job information', () => {
        expect(
          vm.$el
            .querySelector('.header-main-content')
            .textContent.replace(/\s+/g, ' ')
            .trim(),
        ).toEqual('failed Job #123 triggered 2 days ago by Foo');
      });

      it('should render new issue link', () => {
        expect(vm.$el.querySelector('.js-new-issue').getAttribute('href')).toEqual(
          job.new_issue_path,
        );
      });
    });

    describe('created job', () => {
      it('should render created key', () => {
        store.dispatch('receiveJobSuccess', Object.assign({}, job, { started: false }));

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        expect(
          vm.$el
            .querySelector('.header-main-content')
            .textContent.replace(/\s+/g, ' ')
            .trim(),
        ).toEqual('failed Job #123 created 3 weeks ago by Foo');
      });
    });
  });

  describe('stuck block', () => {
    it('renders stuck block when there are no runners', () => {
      store.dispatch(
        'receiveJobSuccess',
        Object.assign({}, job, {
          status: {
            group: 'pending',
            icon: 'status_pending',
            label: 'pending',
            text: 'pending',
            details_path: 'path',
          },
        }),
      );

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-stuck')).not.toBeNull();
    });

    it('renders tags in stuck block when there are no runners', () => {
      store.dispatch(
        'receiveJobSuccess',
        Object.assign({}, job, {
          status: {
            group: 'pending',
            icon: 'status_pending',
            label: 'pending',
            text: 'pending',
            details_path: 'path',
          },
        }),
      );

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-stuck').textContent).toContain(job.tags[0]);
    });

    it(' does not renders stuck block when there are no runners', () => {
      store.dispatch('receiveJobSuccess', Object.assign({}, job, { runners: { available: true } }));

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-stuck')).toBeNull();
    });
  });

  // ee-only start
  describe('runners limit - ee', () => {
    describe('with used quota', () => {
      it('renders used quota', () => {
        store.dispatch(
          'receiveJobSuccess',
          Object.assign({}, job, { quota: { used: 900, limit: 800 } }),
        );

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });
        expect(vm.$el.querySelector('.js-shared-runner-limit')).toBeNull();
      });
    });

    describe('without used quota', () => {
      it('does not render used quota', () => {
        store.dispatch('receiveJobSuccess', job);

        vm = mountComponentWithStore(Component, {
          props,
          store,
        });

        expect(vm.$el.querySelector('.js-shared-runner-limit')).toBeNull();
      });
    });
  });

  // ee-only end

  describe('environments block', () => {
    it('renders environment block when job has environment', () => {
      store.dispatch(
        'receiveJobSuccess',
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

      expect(vm.$el.querySelector('.js-job-environment')).not.toBeNull();
    });

    it('does not render environment block when job has environment', () => {
      store.dispatch('receiveJobSuccess', job);

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-environment')).toBeNull();
    });
  });

  describe('erased block', () => {
    it('renders erased block when `erased` is true', () => {
      store.dispatch(
        'receiveJobSuccess',
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

      expect(vm.$el.querySelector('.js-job-erased-block')).not.toBeNull();
    });

    it('does not render erased block when `erased` is false', () => {
      store.dispatch('receiveJobSuccess', Object.assign({}, job, { erased_at: null }));

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-erased-block')).toBeNull();
    });
  });

  describe('empty states block', () => {
    it('renders empty state when job does not have trace and is not running', () => {
      store.dispatch(
        'receiveJobSuccess',
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

      expect(vm.$el.querySelector('.js-job-empty-state')).not.toBeNull();
    });

    it('does not render empty state when job does not have trace but it is running', () => {
      store.dispatch(
        'receiveJobSuccess',
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

      expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();
    });

    it('does not render empty state when job has trace but it is not running', () => {
      store.dispatch('receiveJobSuccess', Object.assign({}, job, { has_trace: true }));

      vm = mountComponentWithStore(Component, {
        props,
        store,
      });

      expect(vm.$el.querySelector('.js-job-empty-state')).toBeNull();
    });
  });
});
