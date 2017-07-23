import Vue from 'vue';
import notAllowedComponent from '~/vue_merge_request_widget/components/states/mr_widget_not_allowed';

describe('MRWidgetNotAllowed', () => {
  describe('template', () => {
    const Component = Vue.extend(notAllowedComponent);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('Ready to be merged automatically.');
      expect(vm.$el.innerText).toContain('Ask someone with write access to this repository to merge this request.');
    });
  });
});
