import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import eventHub from '~/vue_merge_request_widget/event_hub';
import component from '~/vue_merge_request_widget/components/states/mr_widget_rebase.vue';

describe('Merge request widget rebase component', () => {
  let Component;
  let vm;
  beforeEach(() => {
    Component = Vue.extend(component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('While rebasing', () => {
    it('should show progress message', () => {
      vm = mountComponent(Component, {
        mr: { rebaseInProgress: true },
        service: {},
      });

      expect(
        vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim(),
      ).toContain('Rebase in progress');
    });
  });

  describe('With permissions', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: true,
        },
        service: {},
      });
    });

    it('it should render rebase button and warning message', () => {
      const text = vm.$el
        .querySelector('.rebase-state-find-class-convention span')
        .textContent.trim();

      expect(text).toContain('Fast-forward merge is not possible.');
      expect(text.replace(/\s\s+/g, ' ')).toContain(
        'Rebase the source branch onto the target branch or merge target',
      );

      expect(text).toContain('branch into source branch to allow this merge request to be merged.');
    });

    it('it should render error message when it fails', done => {
      vm.rebasingError = 'Something went wrong!';

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim(),
        ).toContain('Something went wrong!');
        done();
      });
    });
  });

  describe('Without permissions', () => {
    it('should render a message explaining user does not have permissions', () => {
      vm = mountComponent(Component, {
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: false,
          targetBranch: 'foo',
        },
        service: {},
      });

      const text = vm.$el
        .querySelector('.rebase-state-find-class-convention span')
        .textContent.trim();

      expect(text).toContain('Fast-forward merge is not possible.');
      expect(text).toContain('Rebase the source branch onto');
      expect(text).toContain('foo');
      expect(text.replace(/\s\s+/g, ' ')).toContain('to allow this merge request to be merged.');
    });

    it('should render the correct target branch name', () => {
      const targetBranch = 'fake-branch-to-test-with';
      vm = mountComponent(Component, {
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: false,
          targetBranch,
        },
        service: {},
      });

      const elem = vm.$el.querySelector('.rebase-state-find-class-convention span');

      expect(elem.innerHTML).toContain(
        `Fast-forward merge is not possible. Rebase the source branch onto <span class="label-branch">${targetBranch}</span> to allow this merge request to be merged.`,
      );
    });
  });

  describe('methods', () => {
    it('checkRebaseStatus', done => {
      spyOn(eventHub, '$emit');
      vm = mountComponent(Component, {
        mr: {},
        service: {
          rebase() {
            return Promise.resolve();
          },
          poll() {
            return Promise.resolve({
              data: {
                rebase_in_progress: false,
                merge_error: null,
              },
            });
          },
        },
      });

      vm.rebase();

      // Wait for the rebase request
      vm.$nextTick()
        // Wait for the polling request
        .then(vm.$nextTick())
        // Wait for the eventHub to be called
        .then(vm.$nextTick())
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetRebaseSuccess');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
