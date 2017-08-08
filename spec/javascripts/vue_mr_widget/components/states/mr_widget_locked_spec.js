import Vue from 'vue';
import mergingComponent from '~/vue_merge_request_widget/components/states/mr_widget_merging';

describe('MRWidgetMerging', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = mergingComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const Component = Vue.extend(mergingComponent);
      const mr = {
        targetBranchPath: '/branch-path',
        targetBranch: 'branch',
      };
      const el = new Component({
        el: document.createElement('div'),
        propsData: { mr },
      }).$el;

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain('This merge request is in the process of being merged');
      expect(el.innerText).toContain('changes will be merged into');
      expect(el.querySelector('.label-branch a').getAttribute('href')).toEqual(mr.targetBranchPath);
      expect(el.querySelector('.label-branch a').textContent).toContain(mr.targetBranch);
    });
  });
});
