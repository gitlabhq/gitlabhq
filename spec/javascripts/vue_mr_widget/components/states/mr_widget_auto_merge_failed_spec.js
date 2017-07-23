import Vue from 'vue';
import autoMergeFailedComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_failed';

const mergeError = 'This is the merge error';

describe('MRWidgetAutoMergeFailed', () => {
  describe('props', () => {
    it('should have props', () => {
      const mrProp = autoMergeFailedComponent.props.mr;

      expect(mrProp.type instanceof Object).toBeTruthy();
      expect(mrProp.required).toBeTruthy();
    });
  });

  describe('template', () => {
    const Component = Vue.extend(autoMergeFailedComponent);
    const vm = new Component({
      el: document.createElement('div'),
      propsData: {
        mr: { mergeError },
      },
    });

    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('This merge request failed to be merged automatically.');
      expect(vm.$el.innerText).toContain(mergeError);
    });
  });
});
