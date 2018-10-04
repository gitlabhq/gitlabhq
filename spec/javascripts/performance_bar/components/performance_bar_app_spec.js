import Vue from 'vue';
import performanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('performance bar app', () => {
  let vm;

  beforeEach(() => {
    const store = new PerformanceBarStore();

    vm = mountComponent(Vue.extend(performanceBarApp), {
      store,
      env: 'development',
      requestId: '123',
      peekUrl: '/-/peek/results',
      profileUrl: '?lineprofiler=true',
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('sets the class to match the environment', () => {
    expect(vm.$el.getAttribute('class')).toContain('development');
  });
});
