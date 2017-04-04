import Vue from 'vue';
import pipelineBlockedComponent from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_blocked';

describe('MRWidgetPipelineBlocked', () => {
  describe('template', () => {
    const Component = Vue.extend(pipelineBlockedComponent);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('Pipeline blocked. The pipeline for this merge request requires a manual action to proceed.');
    });
  });
});
