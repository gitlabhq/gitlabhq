import Vue from 'vue';
import Description from '~/ide/components/jobs/detail/description.vue';
import mountComponent from '../../../../helpers/vue_mount_component_helper';
import { jobs } from '../../../mock_data';

describe('IDE job description', () => {
  const Component = Vue.extend(Description);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      job: jobs[0],
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders job details', () => {
    expect(vm.$el.textContent).toContain('#1');
    expect(vm.$el.textContent).toContain('test');
  });

  it('renders CI icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon .ic-status_passed_borderless')).not.toBe(null);
  });
});
