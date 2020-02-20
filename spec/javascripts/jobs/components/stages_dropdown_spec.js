import Vue from 'vue';
import { trimText } from 'spec/helpers/text_helper';
import component from '~/jobs/components/stages_dropdown.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Stages Dropdown', () => {
  const Component = Vue.extend(component);
  let vm;

  const mockPipelineData = {
    id: 28029444,
    details: {
      status: {
        details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
        group: 'success',
        has_details: true,
        icon: 'status_success',
        label: 'passed',
        text: 'passed',
        tooltip: 'passed',
      },
    },
    path: 'pipeline/28029444',
    flags: {
      merge_request_pipeline: true,
      detached_merge_request_pipeline: false,
    },
    merge_request: {
      iid: 1234,
      path: '/root/detached-merge-request-pipelines/-/merge_requests/1',
      title: 'Update README.md',
      source_branch: 'feature-1234',
      source_branch_path: '/root/detached-merge-request-pipelines/branches/feature-1234',
      target_branch: 'master',
      target_branch_path: '/root/detached-merge-request-pipelines/branches/master',
    },
    ref: {
      name: 'test-branch',
    },
  };

  describe('without a merge request pipeline', () => {
    let pipeline;

    beforeEach(() => {
      pipeline = JSON.parse(JSON.stringify(mockPipelineData));
      delete pipeline.merge_request;
      delete pipeline.flags.merge_request_pipeline;
      delete pipeline.flags.detached_merge_request_pipeline;

      vm = mountComponent(Component, {
        pipeline,
        stages: [{ name: 'build' }, { name: 'test' }],
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

    it(`renders the pipeline info text like "Pipeline #123 for source_branch"`, () => {
      const expected = `Pipeline #${pipeline.id} for ${pipeline.ref.name}`;
      const actual = trimText(vm.$el.querySelector('.js-pipeline-info').innerText);

      expect(actual).toBe(expected);
    });
  });

  describe('with an "attached" merge request pipeline', () => {
    let pipeline;

    beforeEach(() => {
      pipeline = JSON.parse(JSON.stringify(mockPipelineData));
      pipeline.flags.merge_request_pipeline = true;
      pipeline.flags.detached_merge_request_pipeline = false;

      vm = mountComponent(Component, {
        pipeline,
        stages: [],
        selectedStage: 'deploy',
      });
    });

    it(`renders the pipeline info text like "Pipeline #123 for !456 with source_branch into target_branch"`, () => {
      const expected = `Pipeline #${pipeline.id} for !${pipeline.merge_request.iid} with ${pipeline.merge_request.source_branch} into ${pipeline.merge_request.target_branch}`;
      const actual = trimText(vm.$el.querySelector('.js-pipeline-info').innerText);

      expect(actual).toBe(expected);
    });

    it(`renders the correct merge request link`, () => {
      const actual = vm.$el.querySelector('.js-mr-link').href;

      expect(actual).toContain(pipeline.merge_request.path);
    });

    it(`renders the correct source branch link`, () => {
      const actual = vm.$el.querySelector('.js-source-branch-link').href;

      expect(actual).toContain(pipeline.merge_request.source_branch_path);
    });

    it(`renders the correct target branch link`, () => {
      const actual = vm.$el.querySelector('.js-target-branch-link').href;

      expect(actual).toContain(pipeline.merge_request.target_branch_path);
    });
  });

  describe('with a detached merge request pipeline', () => {
    let pipeline;

    beforeEach(() => {
      pipeline = JSON.parse(JSON.stringify(mockPipelineData));
      pipeline.flags.merge_request_pipeline = false;
      pipeline.flags.detached_merge_request_pipeline = true;

      vm = mountComponent(Component, {
        pipeline,
        stages: [],
        selectedStage: 'deploy',
      });
    });

    it(`renders the pipeline info like "Pipeline #123 for !456 with source_branch"`, () => {
      const expected = `Pipeline #${pipeline.id} for !${pipeline.merge_request.iid} with ${pipeline.merge_request.source_branch}`;
      const actual = trimText(vm.$el.querySelector('.js-pipeline-info').innerText);

      expect(actual).toBe(expected);
    });

    it(`renders the correct merge request link`, () => {
      const actual = vm.$el.querySelector('.js-mr-link').href;

      expect(actual).toContain(pipeline.merge_request.path);
    });

    it(`renders the correct source branch link`, () => {
      const actual = vm.$el.querySelector('.js-source-branch-link').href;

      expect(actual).toContain(pipeline.merge_request.source_branch_path);
    });
  });
});
