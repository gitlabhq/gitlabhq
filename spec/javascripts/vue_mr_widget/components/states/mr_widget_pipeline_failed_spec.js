import Vue from 'vue';
import pipelineFailedComponent from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_failed';

describe('MRWidgetPipelineFailed', () => {
  describe('template', () => {
    const Component = Vue.extend(pipelineFailedComponent);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(vm.$el.innerText).toContain('The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure');
    });
  });
});
