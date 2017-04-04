import Vue from 'vue';
import nothingToMergeComponent from '~/vue_merge_request_widget/components/states/mr_widget_nothing_to_merge';

describe('MRWidgetNothingToMerge', () => {
  describe('template', () => {
    const Component = Vue.extend(nothingToMergeComponent);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('There is nothing to merge from source branch into target branch.');
      expect(vm.$el.innerText).toContain('Please push new commits or use a different branch.');
    });
  });
});
