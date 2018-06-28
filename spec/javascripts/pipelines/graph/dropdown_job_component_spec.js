import Vue from 'vue';
import component from '~/pipelines/components/graph/dropdown_job_component.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('dropdown job component', () => {
  const Component = Vue.extend(component);
  let vm;

  const mock = {
    jobs: [
      {
        id: 4256,
        name: '<img src=x onerror=alert(document.domain)>',
        status: {
          icon: 'icon_status_success',
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
          icon: 'icon_status_success',
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
      icon: 'icon_status_success',
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
    vm = mountComponent(Component, { job: mock });
  });

  it('renders button with job name and size', () => {
    expect(vm.$el.querySelector('button').textContent).toContain(mock.name);
    expect(vm.$el.querySelector('button').textContent).toContain(mock.size);
  });

  it('renders dropdown with jobs', () => {
    expect(vm.$el.querySelectorAll('.scrollable-menu>ul>li').length).toEqual(mock.jobs.length);
  });

  it('escapes tooltip title', () => {
    expect(
      vm.$el.querySelector('.js-pipeline-graph-job-link').getAttribute('data-original-title'),
    ).toEqual(
      '&lt;img src=x onerror=alert(document.domain)&gt; - passed',
    );
  });
});
