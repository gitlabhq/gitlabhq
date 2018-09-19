import Vue from 'vue';
import component from '~/jobs/components/jobs_container.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Artifacts block', () => {
  const Component = Vue.extend(component);
  let vm;

  const retried = {
    status: {
      details_path: '/gitlab-org/gitlab-ce/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    path: 'job/233432756',
    id: '233432756',
    tooltip: 'build - passed',
    retried: true,
  };

  const active = {
    name: 'test',
    status: {
      details_path: '/gitlab-org/gitlab-ce/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    path: 'job/2322756',
    id: '2322756',
    tooltip: 'build - passed',
    active: true,
  };

  const job = {
    name: 'build',
    status: {
      details_path: '/gitlab-org/gitlab-ce/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
    path: 'job/232153',
    id: '232153',
    tooltip: 'build - passed',
  };

  afterEach(() => {
    vm.$destroy();
  });

  it('renders list of jobs', () => {
    vm = mountComponent(Component, {
      jobs: [job, retried, active],
    });

    expect(vm.$el.querySelectorAll('a').length).toEqual(3);
  });

  it('renders arrow right when job is active', () => {
    vm = mountComponent(Component, {
      jobs: [active],
    });

    expect(vm.$el.querySelector('a .js-arrow-right')).not.toBeNull();
  });

  it('does not render arrow right when job is not active', () => {
    vm = mountComponent(Component, {
      jobs: [job],
    });

    expect(vm.$el.querySelector('a .js-arrow-right')).toBeNull();
  });

  it('renders job name when present', () => {
    vm = mountComponent(Component, {
      jobs: [job],
    });

    expect(vm.$el.querySelector('a').textContent.trim()).toContain(job.name);
    expect(vm.$el.querySelector('a').textContent.trim()).not.toContain(job.id);
  });

  it('renders job id when job name is not available', () => {
    vm = mountComponent(Component, {
      jobs: [retried],
    });

    expect(vm.$el.querySelector('a').textContent.trim()).toContain(retried.id);
  });

  it('links to the job page', () => {
    vm = mountComponent(Component, {
      jobs: [job],
    });

    expect(vm.$el.querySelector('a').getAttribute('href')).toEqual(job.path);
  });

  it('renders retry icon when job was retried', () => {
    vm = mountComponent(Component, {
      jobs: [retried],
    });

    expect(vm.$el.querySelector('.js-retry-icon')).not.toBeNull();
  });

  it('does not render retry icon when job was not retried', () => {
    vm = mountComponent(Component, {
      jobs: [job],
    });

    expect(vm.$el.querySelector('.js-retry-icon')).toBeNull();
  });
});
