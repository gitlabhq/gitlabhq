import Vue from 'vue';
import mwpsComponent from '~/vue_merge_request_widget/components/states/mr_widget_merge_when_pipeline_succeeds.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import eventHub from '~/vue_merge_request_widget/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetMergeWhenPipelineSucceeds', () => {
  let vm;
  const targetBranchPath = '/foo/bar';
  const targetBranch = 'foo';
  const sha = '1EA2EZ34';

  beforeEach(() => {
    const Component = Vue.extend(mwpsComponent);
    spyOn(eventHub, '$emit');

    vm = mountComponent(Component, {
      mr: {
        shouldRemoveSourceBranch: false,
        canRemoveSourceBranch: true,
        canCancelAutomaticMerge: true,
        mergeUserId: 1,
        currentUserId: 1,
        setToMWPSBy: {},
        sha,
        targetBranchPath,
        targetBranch,
      },
      service: new MRWidgetService({}),
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('canRemoveSourceBranch', () => {
      it('should return true when user is able to remove source branch', () => {
        expect(vm.canRemoveSourceBranch).toBeTruthy();
      });

      it('should return false when user id is not the same with who set the MWPS', () => {
        vm.mr.mergeUserId = 2;
        expect(vm.canRemoveSourceBranch).toBeFalsy();

        vm.mr.currentUserId = 2;
        expect(vm.canRemoveSourceBranch).toBeTruthy();

        vm.mr.currentUserId = 3;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });

      it('should return false when shouldRemoveSourceBranch set to false', () => {
        vm.mr.shouldRemoveSourceBranch = true;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });

      it('should return false if user is not able to remove the source branch', () => {
        vm.mr.canRemoveSourceBranch = false;
        expect(vm.canRemoveSourceBranch).toBeFalsy();
      });
    });
  });

  describe('methods', () => {
    describe('cancelAutomaticMerge', () => {
      it('should set flag and call service then tell main component to update the widget with data', (done) => {
        const mrObj = {
          is_new_mr_data: true,
        };
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
        spyOn(vm.service, 'merge').and.returnValue(Promise.resolve({
          data: {
            status: 'merge_when_pipeline_succeeds',
          },
        }));

        vm.removeSourceBranch();
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          expect(vm.service.merge).toHaveBeenCalledWith({
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
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.innerText).toContain('to be merged automatically when the pipeline succeeds');
      expect(vm.$el.innerText).toContain('The changes will be merged into');
      expect(vm.$el.innerText).toContain(targetBranch);
      expect(vm.$el.innerText).toContain('The source branch will not be removed');
      expect(vm.$el.querySelector('.js-cancel-auto-merge').innerText).toContain('Cancel automatic merge');
      expect(vm.$el.querySelector('.js-cancel-auto-merge').getAttribute('disabled')).toBeFalsy();
      expect(vm.$el.querySelector('.js-remove-source-branch').innerText).toContain('Remove source branch');
      expect(vm.$el.querySelector('.js-remove-source-branch').getAttribute('disabled')).toBeFalsy();
    });

    it('should disable cancel auto merge button when the action is in progress', (done) => {
      vm.isCancellingAutoMerge = true;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-cancel-auto-merge').getAttribute('disabled')).toBeTruthy();
        done();
      });
    });

    it('should show source branch will be removed text when it source branch set to remove', (done) => {
      vm.mr.shouldRemoveSourceBranch = true;

      Vue.nextTick(() => {
        const normalizedText = vm.$el.innerText.replace(/\s+/g, ' ');
        expect(normalizedText).toContain('The source branch will be removed');
        expect(normalizedText).not.toContain('The source branch will not be removed');
        done();
      });
    });

    it('should not show remove source branch button when user not able to remove source branch', (done) => {
      vm.mr.currentUserId = 4;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-remove-source-branch')).toEqual(null);
        done();
      });
    });

    it('should disable remove source branch button when the action is in progress', (done) => {
      vm.isRemovingSourceBranch = true;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-remove-source-branch').getAttribute('disabled')).toBeTruthy();
        done();
      });
    });
  });
});
