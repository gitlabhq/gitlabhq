import Vue from 'vue';
import NothingToMerge from '~/vue_merge_request_widget/components/states/nothing_to_merge.vue';

describe('NothingToMerge', () => {
  describe('template', () => {
    const Component = Vue.extend(NothingToMerge);
    const newBlobPath = '/foo';
    const vm = new Component({
      el: document.createElement('div'),
      propsData: {
        mr: { newBlobPath },
      },
    });

    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('a').href).toContain(newBlobPath);
      expect(vm.$el.innerText).toContain('Currently there are no changes in this merge request\'s source branch');
      expect(vm.$el.innerText).toContain('Please push new commits or use a different branch.');
    });

    it('should not show new blob link if there is no link available', () => {
      vm.mr.newBlobPath = null;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('a')).toEqual(null);
      });
    });
  });
});
