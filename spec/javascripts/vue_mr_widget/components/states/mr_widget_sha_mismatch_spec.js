import Vue from 'vue';
import ShaMismatch from '~/vue_merge_request_widget/components/states/sha_mismatch.vue';

describe('ShaMismatch', () => {
  describe('template', () => {
    const Component = Vue.extend(ShaMismatch);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('The source branch HEAD has recently changed.');
      expect(vm.$el.innerText).toContain('Please reload the page and review the changes before merging.');
    });
  });
});
