import Vue from 'vue';
import component from '~/jobs/components/stages_dropdown.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Stages Dropdown', () => {
  const Component = Vue.extend(component);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      pipeline: {
        id: 28029444,
        details: {
          status: {
            details_path: '/gitlab-org/gitlab-ce/pipelines/28029444',
            group: 'success',
            has_details: true,
            icon: 'status_success',
            label: 'passed',
            text: 'passed',
            tooltip: 'passed',
          },
        },
        path: 'pipeline/28029444',
      },
      stages: [
        {
          name: 'build',
        },
        {
          name: 'test',
        },
      ],
      selectedStage: 'deploy',
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
    expect(vm.$el.querySelector('.dropdown .js-stage-item').textContent).toContain('build');
  });

  it('rendes selected stage', () => {
    expect(vm.$el.querySelector('.dropdown .js-selected-stage').textContent).toContain('deploy');
  });
});
