import Vue from 'vue';
import component from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('performance issue body', () => {
  let vm;

  const Component = Vue.extend(component);

  const performanceIssue = {
    delta: 0.1999999999998181,
    name: 'Transfer Size (KB)',
    path: '/',
    score: 4974.8,
  };

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    vm = mountComponent(Component, {
      issue: performanceIssue,
    });
  });

  it('renders issue name', () => {
    expect(vm.$el.textContent.trim()).toContain(performanceIssue.name);
  });

  it('renders issue score formatted', () => {
    expect(vm.$el.textContent.trim()).toContain('4974.80');
  });

  it('renders issue delta formatted', () => {
    expect(vm.$el.textContent.trim()).toContain('(+0.20)');
  });
});
