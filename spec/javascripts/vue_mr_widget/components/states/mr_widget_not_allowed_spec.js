import Vue from 'vue';
import notAllowedComponent from '~/vue_merge_request_widget/components/states/mr_widget_not_allowed.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetNotAllowed', () => {
  let vm;
  beforeEach(() => {
    const Component = Vue.extend(notAllowedComponent);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders success icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon-success')).not.toBe(null);
  });

  it('renders informative text', () => {
    expect(vm.$el.innerText).toContain('Ready to be merged automatically.');
    expect(vm.$el.innerText).toContain('Ask someone with write access to this repository to merge this request');
  });
});
