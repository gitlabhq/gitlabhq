import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/summary_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Summary row', () => {
  const Component = Vue.extend(component);
  let vm;

  const props = {
    summary: 'SAST detected 1 new vulnerability and 1 fixed vulnerability',
    popoverTitle: 'Static Application Security Testing (SAST)',
    popoverContent: '<a>Learn more about SAST</a>',
    statusIcon: 'warning',
  };

  beforeEach(() => {
    vm = mountComponent(Component, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders provided summary', () => {
    expect(
      vm.$el.querySelector('.report-block-list-issue-description-text').textContent.trim(),
    ).toEqual(props.summary);
  });

  it('renders provided icon', () => {
    expect(vm.$el.querySelector('.report-block-list-icon span').classList).toContain(
      'js-ci-status-icon-warning',
    );
  });

  it('renders tooltip with provided title and content', () => {
    expect(vm.popoverOptions.title).toEqual(props.popoverTitle);
    expect(vm.popoverOptions.content).toEqual(props.popoverContent);
  });
});
