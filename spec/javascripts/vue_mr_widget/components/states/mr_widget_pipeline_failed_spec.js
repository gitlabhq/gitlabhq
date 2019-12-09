import Vue from 'vue';
import { removeBreakLine } from 'spec/helpers/text_helper';
import PipelineFailed from '~/vue_merge_request_widget/components/states/pipeline_failed.vue';

describe('PipelineFailed', () => {
  describe('template', () => {
    const Component = Vue.extend(PipelineFailed);
    const vm = new Component({
      el: document.createElement('div'),
    });
    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(removeBreakLine(vm.$el.innerText).trim()).toContain(
        'The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure',
      );
    });
  });
});
