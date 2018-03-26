import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/loading_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('loading row', () => {
  const Component = Vue.extend(component);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders loading icon with message', () => {
    expect(vm.$el.querySelector('.report-block-list-icon i').classList).toContain('fa-spin');
    expect(vm.$el.querySelector('.report-block-list-issue-description').textContent.trim()).toEqual(
      'in progress',
    );
  });
});
