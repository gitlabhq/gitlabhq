import Vue from 'vue';
import component from '~/jobs/components/stages_dropdown.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Artifacts block', () => {
  const Component = Vue.extend(component);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      pipelineId: 28029444,
      pipelinePath: 'pipeline/28029444',
      pipelineRef: '50101-truncated-job-information',
      pipelineRefPath: 'commits/50101-truncated-job-information',
      stages: [
        {
          name: 'build',
        },
        {
          name: 'test',
        },
      ],
      pipelineStatus: {
        details_path: '/gitlab-org/gitlab-ce/pipelines/28029444',
        group: 'success',
        has_details: true,
        icon: 'status_success',
        label: 'passed',
        text: 'passed',
        tooltip: 'passed',
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders pipeline status', () => {
    expect(vm.$el.querySelector('.js-ci-status-icon-success')).not.toBeNull();
  });

  it('renders pipeline link', () => {
    expect(vm.$el.querySelector('.js-pipeline-path').getAttribute('href')).toEqual(
      'pipeline/28029444',
    );
  });

  it('renders dropdown with stages', () => {
    expect(vm.$el.querySelector('.dropdown button').textContent).toContain('build');
  });

  it('updates selected stage on click', done => {
    vm.$el.querySelectorAll('.stage-item')[1].click();
    vm
      .$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.dropdown button').textContent).toContain('test');
      })
      .then(done)
      .catch(done.fail);
  });
});
