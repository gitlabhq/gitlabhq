import Vue from 'vue';
import missingBranchComponent from '~/vue_merge_request_widget/components/states/mr_widget_missing_branch.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetMissingBranch', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(missingBranchComponent);
    vm = mountComponent(Component, { mr: { sourceBranchRemoved: true } });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('missingBranchName', () => {
      it('should return proper branch name', () => {
        expect(vm.missingBranchName).toEqual('source');

        vm.mr.sourceBranchRemoved = false;
        expect(vm.missingBranchName).toEqual('target');
      });
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = vm.$el;
      const content = el.textContent.replace(/\n(\s)+/g, ' ').trim();

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(content).toContain('source branch does not exist.');
      expect(content).toContain('Please restore it or use a different source branch');
    });
  });
});
