import Vue from 'vue';
import lockedComponent from '~/vue_merge_request_widget/components/states/mr_widget_locked';

describe('MRWidgetLocked', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = lockedComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const Component = Vue.extend(lockedComponent);
      const mr = {
        targetBranchPath: '/branch-path',
        targetBranch: 'branch',
      };
      const el = new Component({
        el: document.createElement('div'),
        propsData: { mr },
      }).$el;

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain('it is locked');
      expect(el.innerText).toContain('changes will be merged into');
      expect(el.querySelector('.monospace a').getAttribute('href')).toEqual(mr.targetBranchPath);
      expect(el.querySelector('.monospace a').textContent).toContain(mr.targetBranch);
    });
  });
});
