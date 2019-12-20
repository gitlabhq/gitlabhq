import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import JobGroupDropdown from '~/pipelines/components/graph/job_group_dropdown.vue';

describe('job group dropdown component', () => {
  const Component = Vue.extend(JobGroupDropdown);
  let vm;

  const group = {
    jobs: [
      {
        id: 4256,
        name: '<img src=x onerror=alert(document.domain)>',
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          tooltip: 'passed',
          group: 'success',
          details_path: '/root/ci-mock/builds/4256',
          has_details: true,
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/root/ci-mock/builds/4256/retry',
            method: 'post',
          },
        },
      },
      {
        id: 4299,
        name: 'test',
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          tooltip: 'passed',
          group: 'success',
          details_path: '/root/ci-mock/builds/4299',
          has_details: true,
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/root/ci-mock/builds/4299/retry',
            method: 'post',
          },
        },
      },
    ],
    name: 'rspec:linux',
    size: 2,
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4256',
      has_details: true,
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
  };

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    vm = mountComponent(Component, { group });
  });

  it('renders button with group name and size', () => {
    expect(vm.$el.querySelector('button').textContent).toContain(group.name);
    expect(vm.$el.querySelector('button').textContent).toContain(group.size);
  });

  it('renders dropdown with jobs', () => {
    expect(vm.$el.querySelectorAll('.scrollable-menu>ul>li').length).toEqual(group.jobs.length);
  });
});
