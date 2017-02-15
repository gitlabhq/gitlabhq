import Vue from 'vue';
import checkingComponent from '~/vue_merge_request_widget/components/states/mr_widget_checking';

describe('MRWidgetChecking', () => {
  describe('template', () => {
    it('should have correct elements', () => {
      const Component = Vue.extend(checkingComponent);
      const el = new Component({
        el: document.createElement('div'),
      }).$el;

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.querySelector('button').classList.contains('btn-success')).toBeTruthy();
      expect(el.querySelector('button').disabled).toBeTruthy();
      expect(el.innerText).toContain('Checking ability to merge automatically.');
      expect(el.querySelector('i')).toBeDefined();
    });
  });
});
