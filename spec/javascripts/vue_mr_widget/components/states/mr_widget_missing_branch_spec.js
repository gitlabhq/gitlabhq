import Vue from 'vue';
import missingBranchComponent from '~/vue_merge_request_widget/components/states/mr_widget_missing_branch';

const createComponent = () => {
  const Component = Vue.extend(missingBranchComponent);
  const mr = {
    sourceBranchRemoved: true,
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetMissingBranch', () => {
  describe('props', () => {
    it('should have props', () => {
      const mrProp = missingBranchComponent.props.mr;

      expect(mrProp.type instanceof Object).toBeTruthy();
      expect(mrProp.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(missingBranchComponent.components['mr-widget-merge-help']).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('missingBranchName', () => {
      it('should return proper branch name', () => {
        const vm = createComponent();
        expect(vm.missingBranchName).toEqual('source');

        vm.mr.sourceBranchRemoved = false;
        expect(vm.missingBranchName).toEqual('target');
      });
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = createComponent().$el;
      const content = el.textContent.replace(/\n(\s)+/g, ' ').trim();

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(content).toContain('source branch does not exist.');
      expect(content).toContain('Please restore the source branch or use a different source branch.');
    });
  });
});
