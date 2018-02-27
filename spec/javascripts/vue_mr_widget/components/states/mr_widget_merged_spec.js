import Vue from 'vue';
import mergedComponent from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetMerged', () => {
  let vm;
  const targetBranch = 'foo';

  beforeEach(() => {
    const Component = Vue.extend(mergedComponent);
    const mr = {
      isRemovingSourceBranch: false,
      cherryPickInForkPath: false,
      canCherryPickInCurrentMR: true,
      revertInForkPath: false,
      canRevertInCurrentMR: true,
      canRemoveSourceBranch: true,
      sourceBranchRemoved: true,
      metrics: {
        mergedBy: {
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://localhost:3000/root',
          avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
        mergedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        readableMergedAt: '',
        closedBy: {},
        closedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        readableClosedAt: '',
      },
      updatedAt: 'mergedUpdatedAt',
      targetBranch,
    };

    const service = {
      removeSourceBranch() {},
    };

    spyOn(eventHub, '$emit');

    vm = mountComponent(Component, { mr, service });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('shouldShowRemoveSourceBranch', () => {
      it('returns true when sourceBranchRemoved is false', () => {
        vm.mr.sourceBranchRemoved = false;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(true);
      });

      it('returns false wehn sourceBranchRemoved is true', () => {
        vm.mr.sourceBranchRemoved = true;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(false);
      });

      it('returns false when canRemoveSourceBranch is false', () => {
        vm.mr.sourceBranchRemoved = false;
        vm.mr.canRemoveSourceBranch = false;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(false);
      });

      it('returns false when is making request', () => {
        vm.mr.canRemoveSourceBranch = true;
        vm.isMakingRequest = true;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(false);
      });

      it('returns true when all are true', () => {
        vm.mr.isRemovingSourceBranch = true;
        vm.mr.canRemoveSourceBranch = true;
        vm.isMakingRequest = true;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(false);
      });
    });

    describe('shouldShowSourceBranchRemoving', () => {
      it('should correct value when fields changed', () => {
        vm.mr.sourceBranchRemoved = false;
        expect(vm.shouldShowSourceBranchRemoving).toEqual(false);

        vm.mr.sourceBranchRemoved = true;
        expect(vm.shouldShowRemoveSourceBranch).toEqual(false);

        vm.mr.sourceBranchRemoved = false;
        vm.isMakingRequest = true;
        expect(vm.shouldShowSourceBranchRemoving).toEqual(true);

        vm.isMakingRequest = false;
        vm.mr.isRemovingSourceBranch = true;
        expect(vm.shouldShowSourceBranchRemoving).toEqual(true);
      });
    });
  });

  describe('methods', () => {
    describe('removeSourceBranch', () => {
      it('should set flag and call service then request main component to update the widget', (done) => {
        spyOn(vm.service, 'removeSourceBranch').and.returnValue(new Promise((resolve) => {
          resolve({
            data: {
              message: 'Branch was removed',
            },
          });
        }));

        vm.removeSourceBranch();
        setTimeout(() => {
          const args = eventHub.$emit.calls.argsFor(0);
          expect(vm.isMakingRequest).toEqual(true);
          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).not.toThrow();
          done();
        }, 333);
      });
    });
  });

  it('has merged by information', () => {
    expect(vm.$el.textContent).toContain('Merged by');
    expect(vm.$el.textContent).toContain('Administrator');
  });

  it('renders branch information', () => {
    expect(vm.$el.textContent).toContain('The changes were merged into');
    expect(vm.$el.textContent).toContain(targetBranch);
  });

  it('renders information about branch being removed', () => {
    expect(vm.$el.textContent).toContain('The source branch has been removed');
  });

  it('shows revert and cherry-pick buttons', () => {
    expect(vm.$el.textContent).toContain('Revert');
    expect(vm.$el.textContent).toContain('Cherry-pick');
  });

  it('should not show source branch removed text', (done) => {
    vm.mr.sourceBranchRemoved = false;

    Vue.nextTick(() => {
      expect(vm.$el.innerText).toContain('You can remove source branch now');
      expect(vm.$el.innerText).not.toContain('The source branch has been removed');
      done();
    });
  });

  it('should show source branch removing text', (done) => {
    vm.mr.isRemovingSourceBranch = true;
    vm.mr.sourceBranchRemoved = false;

    Vue.nextTick(() => {
      expect(vm.$el.innerText).toContain('The source branch is being removed');
      expect(vm.$el.innerText).not.toContain('You can remove source branch now');
      expect(vm.$el.innerText).not.toContain('The source branch has been removed');
      done();
    });
  });

  it('should use mergedEvent mergedAt as tooltip title', () => {
    expect(
      vm.$el.querySelector('time').getAttribute('title'),
    ).toBe('Jan 24, 2018 1:02pm GMT+0000');
  });
});
