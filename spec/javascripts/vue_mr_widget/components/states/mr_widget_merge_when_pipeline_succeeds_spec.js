import Vue from 'vue';
import mwpsComponent from '~/vue_merge_request_widget/components/states/mr_widget_merge_when_pipeline_succeeds';
import eventHub from '~/vue_merge_request_widget/event_hub';

const targetBranchPath = '/foo/bar';
const targetBranch = 'foo';
const sha = '1EA2EZ34';

const createComponent = () => {
  const Component = Vue.extend(mwpsComponent);
  const mr = {
    shouldRemoveSourceBranch: false,
    canRemoveSourceBranch: true,
    canCancelAutomaticMerge: true,
    mergeUserId: 1,
    currentUserId: 1,
    setToMWPSBy: {},
    sha,
    targetBranchPath,
    targetBranch,
  };

  const service = {
    cancelAutomaticMerge() {},
    mergeResource: {
      save() {},
    },
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('MRWidgetMergeWhenPipelineSucceeds', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = mwpsComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(mwpsComponent.components['mr-widget-author']).toBeDefined();
    });
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = mwpsComponent.data();

      expect(data.isCancellingAutoMerge).toBeFalsy();
      expect(data.isRemovingSourceBranch).toBeFalsy();
    });
  });

  describe('computed', () => {
    describe('canRemoveSourceBranch', () => {
      it('should return true when user is able to remove source branch', () => {
        const vm = createComponent();

        expect(vm.canRemoveSourceBranch).toBeTruthy();
      });

      it('should return false when user id is not the same with who set the MWPS', () => {
        const vm = createComponent();

        vm.mr.mergeUserId = 2;
        expect(vm.canRemoveSourceBranch).toBeFalsy();

        vm.mr.currentUserId = 2;
        expect(vm.canRemoveSourceBranch).toBeTruthy();

        vm.mr.currentUserId = 3;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });

      it('should return false when shouldRemoveSourceBranch set to false', () => {
        const vm = createComponent();

        vm.mr.shouldRemoveSourceBranch = true;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });

      it('should return false if user is not able to remove the source branch', () => {
        const vm = createComponent();

        vm.mr.canRemoveSourceBranch = false;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });
    });
  });

  describe('methods', () => {
    describe('cancelAutomaticMerge', () => {
      it('should set flag and call service then tell main component to update the widget with data', (done) => {
        const vm = createComponent();
        const mrObj = {
          is_new_mr_data: true,
        };
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'cancelAutomaticMerge').and.returnValue(new Promise((resolve) => {
          resolve({
            data: mrObj,
          });
        }));

        vm.cancelAutomaticMerge();
        setTimeout(() => {
          expect(vm.isCancellingAutoMerge).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('UpdateWidgetData', mrObj);
          done();
        }, 333);
      });
    });

    describe('removeSourceBranch', () => {
      it('should set flag and call service then request main component to update the widget', (done) => {
        const vm = createComponent();
        spyOn(eventHub, '$emit');
        spyOn(vm.service.mergeResource, 'save').and.returnValue(new Promise((resolve) => {
          resolve({
            data: {
              status: 'merge_when_pipeline_succeeds',
            },
          });
        }));

        vm.removeSourceBranch();
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          expect(vm.service.mergeResource.save).toHaveBeenCalledWith({
            sha,
            merge_when_pipeline_succeeds: true,
            should_remove_source_branch: true,
          });
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
      expect(el.innerText).toContain('to be merged automatically when the pipeline succeeds');
      expect(el.innerText).toContain('The changes will be merged into');
      expect(el.innerText).toContain(targetBranch);
      expect(el.innerText).toContain('The source branch will not be removed');
      expect(el.querySelector('.js-cancel-auto-merge').innerText).toContain('Cancel automatic merge');
      expect(el.querySelector('.js-cancel-auto-merge').getAttribute('disabled')).toBeFalsy();
      expect(el.querySelector('.js-remove-source-branch').innerText).toContain('Remove source branch');
      expect(el.querySelector('.js-remove-source-branch').getAttribute('disabled')).toBeFalsy();
    });

    it('should disable cancel auto merge button when the action is in progress', (done) => {
      vm.isCancellingAutoMerge = true;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-cancel-auto-merge').getAttribute('disabled')).toBeTruthy();
        done();
      });
    });

    it('should show source branch will be removed text when it source branch set to remove', (done) => {
      vm.mr.shouldRemoveSourceBranch = true;

      Vue.nextTick(() => {
        const normalizedText = el.innerText.replace(/\s+/g, ' ');
        expect(normalizedText).toContain('The source branch will be removed');
        expect(normalizedText).not.toContain('The source branch will not be removed');
        done();
      });
    });

    it('should not show remove source branch button when user not able to remove source branch', (done) => {
      vm.mr.currentUserId = 4;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-remove-source-branch')).toEqual(null);
        done();
      });
    });

    it('should disable remove source branch button when the action is in progress', (done) => {
      vm.isRemovingSourceBranch = true;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-remove-source-branch').getAttribute('disabled')).toBeTruthy();
        done();
      });
    });
  });
});
