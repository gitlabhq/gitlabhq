import Vue from 'vue';
import mergedComponent from '~/vue_merge_request_widget/components/states/mr_widget_merged';
import eventHub from '~/vue_merge_request_widget/event_hub';

const targetBranch = 'foo';

const createComponent = () => {
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
      mergedBy: {},
      mergedAt: 'mergedUpdatedAt',
      readableMergedAt: '',
      closedBy: {},
      closedAt: 'mergedUpdatedAt',
      readableClosedAt: '',
    },
    updatedAt: 'mrUpdatedAt',
    targetBranch,
  };

  const service = {
    removeSourceBranch() {},
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('MRWidgetMerged', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = mergedComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(mergedComponent.components['mr-widget-author-and-time']).toBeDefined();
    });
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = mergedComponent.data();

      expect(data.isMakingRequest).toBeFalsy();
    });
  });

  describe('computed', () => {
    describe('shouldShowRemoveSourceBranch', () => {
      it('should correct value when fields changed', () => {
        const vm = createComponent();
        vm.mr.sourceBranchRemoved = false;
        expect(vm.shouldShowRemoveSourceBranch).toBeTruthy();

        vm.mr.sourceBranchRemoved = true;
        expect(vm.shouldShowRemoveSourceBranch).toBeFalsy();

        vm.mr.sourceBranchRemoved = false;
        vm.mr.canRemoveSourceBranch = false;
        expect(vm.shouldShowRemoveSourceBranch).toBeFalsy();

        vm.mr.canRemoveSourceBranch = true;
        vm.isMakingRequest = true;
        expect(vm.shouldShowRemoveSourceBranch).toBeFalsy();

        vm.mr.isRemovingSourceBranch = true;
        vm.mr.canRemoveSourceBranch = true;
        vm.isMakingRequest = true;
        expect(vm.shouldShowRemoveSourceBranch).toBeFalsy();
      });
    });
    describe('shouldShowSourceBranchRemoving', () => {
      it('should correct value when fields changed', () => {
        const vm = createComponent();
        vm.mr.sourceBranchRemoved = false;
        expect(vm.shouldShowSourceBranchRemoving).toBeFalsy();

        vm.mr.sourceBranchRemoved = true;
        expect(vm.shouldShowRemoveSourceBranch).toBeFalsy();

        vm.mr.sourceBranchRemoved = false;
        vm.isMakingRequest = true;
        expect(vm.shouldShowSourceBranchRemoving).toBeTruthy();

        vm.isMakingRequest = false;
        vm.mr.isRemovingSourceBranch = true;
        expect(vm.shouldShowSourceBranchRemoving).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('removeSourceBranch', () => {
      it('should set flag and call service then request main component to update the widget', (done) => {
        const vm = createComponent();
        spyOn(eventHub, '$emit');
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
          expect(vm.isMakingRequest).toBeTruthy();
          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).not.toThrow();
          done();
        }, 333);
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    it('should have correct elements', () => {
      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.querySelector('.js-mr-widget-author')).toBeDefined();
      expect(el.innerText).toContain('The changes were merged into');
      expect(el.innerText).toContain(targetBranch);
      expect(el.innerText).toContain('The source branch has been removed');
      expect(el.innerText).toContain('Revert');
      expect(el.innerText).toContain('Cherry-pick');
      expect(el.innerText).not.toContain('You can remove source branch now');
      expect(el.innerText).not.toContain('The source branch is being removed');
    });

    it('should not show source branch removed text', (done) => {
      vm.mr.sourceBranchRemoved = false;

      Vue.nextTick(() => {
        expect(el.innerText).toContain('You can remove source branch now');
        expect(el.innerText).not.toContain('The source branch has been removed');
        done();
      });
    });

    it('should show source branch removing text', (done) => {
      vm.mr.isRemovingSourceBranch = true;
      vm.mr.sourceBranchRemoved = false;

      Vue.nextTick(() => {
        expect(el.innerText).toContain('The source branch is being removed');
        expect(el.innerText).not.toContain('You can remove source branch now');
        expect(el.innerText).not.toContain('The source branch has been removed');
        done();
      });
    });

    it('should use mergedEvent updatedAt as tooltip title', () => {
      expect(
        el.querySelector('time').getAttribute('title'),
      ).toBe('mergedUpdatedAt');
    });
  });
});
