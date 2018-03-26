import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/error_row.vue';
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

  it('renders warning icon with error message', () => {
    expect(vm.$el.querySelector('.report-block-list-icon span').classList).toContain(
      'js-ci-status-icon-warning',
    );
    expect(vm.$el.querySelector('.report-block-list-issue-description').textContent.trim()).toEqual(
      'There was an error loading results',
    );
  });
});
