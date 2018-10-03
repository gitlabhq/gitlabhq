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
  };

  const props = {
    runnerHelpUrl: 'help/runners',
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
});
