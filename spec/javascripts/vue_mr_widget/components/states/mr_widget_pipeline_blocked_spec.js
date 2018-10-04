import Vue from 'vue';
import pipelineBlockedComponent from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_blocked.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { removeBreakLine } from 'spec/helpers/vue_component_helper';

describe('MRWidgetPipelineBlocked', () => {
  let vm;
  beforeEach(() => {
    const Component = Vue.extend(pipelineBlockedComponent);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders warning icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon-warning')).not.toBe(null);
  });

  it('renders information text', () => {
    expect(
      removeBreakLine(vm.$el.textContent).trim(),
    ).toContain('Pipeline blocked. The pipeline for this merge request requires a manual action to proceed');
  });
});
