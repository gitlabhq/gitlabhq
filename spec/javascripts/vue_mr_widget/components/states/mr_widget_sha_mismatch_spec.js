import Vue from 'vue';
import shaMismatchComponent from '~/vue_merge_request_widget/components/states/mr_widget_sha_mismatch';

describe('MRWidgetSHAMismatch', () => {
  describe('template', () => {
    const Component = Vue.extend(shaMismatchComponent);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('The source branch HEAD has recently changed. Please reload the page and review the changes before merging.');
    });
  });
});
