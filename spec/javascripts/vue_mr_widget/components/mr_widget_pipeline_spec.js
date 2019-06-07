import Vue from 'vue';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/text_helper';
import mockData from '../mock_data';

describe('MRWidgetPipeline', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(pipelineComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasPipeline', () => {
      it('should return true when there is a pipeline', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          ciStatus: 'success',
          hasCi: true,
          troubleshootingDocsPath: 'help',
        });

        expect(vm.hasPipeline).toEqual(true);
      });

      it('should return false when there is no pipeline', () => {
        vm = mountComponent(Component, {
          pipeline: {},
          troubleshootingDocsPath: 'help',
        });

        expect(vm.hasPipeline).toEqual(false);
      });
    });

    describe('hasCIError', () => {
      it('should return false when there is no CI error', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.hasCIError).toEqual(false);
      });

      it('should return true when there is a CI error', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          hasCi: true,
          ciStatus: null,
          troubleshootingDocsPath: 'help',
        });

        expect(vm.hasCIError).toEqual(true);
      });
    });
  });

  describe('rendered output', () => {
    it('should render CI error', () => {
      vm = mountComponent(Component, {
        pipeline: mockData.pipeline,
        hasCi: true,
        ciStatus: null,
        troubleshootingDocsPath: 'help',
      });

      expect(vm.$el.querySelector('.media-body').textContent.trim()).toContain(
        'Could not retrieve the pipeline status. For troubleshooting steps, read the documentation.',
      );
    });

    it('should render CI error when no pipeline is provided', () => {
      vm = mountComponent(Component, {
        pipeline: {},
        hasCi: true,
        ciStatus: 'success',
        troubleshootingDocsPath: 'help',
      });

      expect(vm.$el.querySelector('.media-body').textContent.trim()).toContain(
        'Could not retrieve the pipeline status. For troubleshooting steps, read the documentation.',
      );
    });

    describe('with a pipeline', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });
      });

      it('should render pipeline ID', () => {
        expect(vm.$el.querySelector('.pipeline-id').textContent.trim()).toEqual(
          `#${mockData.pipeline.id} (#${mockData.pipeline.iid})`,
        );
      });

      it('should render pipeline status and commit id', () => {
        expect(vm.$el.querySelector('.media-body').textContent.trim()).toContain(
          mockData.pipeline.details.status.label,
        );

        expect(vm.$el.querySelector('.js-commit-link').textContent.trim()).toEqual(
          mockData.pipeline.commit.short_id,
        );

        expect(vm.$el.querySelector('.js-commit-link').getAttribute('href')).toEqual(
          mockData.pipeline.commit.commit_path,
        );
      });

      it('should render pipeline graph', () => {
        expect(vm.$el.querySelector('.mr-widget-pipeline-graph')).toBeDefined();
        expect(vm.$el.querySelectorAll('.stage-container').length).toEqual(
          mockData.pipeline.details.stages.length,
        );
      });

      it('should render coverage information', () => {
        expect(vm.$el.querySelector('.media-body').textContent).toContain(
          `Coverage ${mockData.pipeline.coverage}`,
        );
      });
    });

    describe('without commit path', () => {
      beforeEach(() => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.commit;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });
      });

      it('should render pipeline ID', () => {
        expect(vm.$el.querySelector('.pipeline-id').textContent.trim()).toEqual(
          `#${mockData.pipeline.id} (#${mockData.pipeline.iid})`,
        );
      });

      it('should render pipeline status', () => {
        expect(vm.$el.querySelector('.media-body').textContent.trim()).toContain(
          mockData.pipeline.details.status.label,
        );

        expect(vm.$el.querySelector('.js-commit-link')).toBeNull();
      });

      it('should render pipeline graph', () => {
        expect(vm.$el.querySelector('.mr-widget-pipeline-graph')).toBeDefined();
        expect(vm.$el.querySelectorAll('.stage-container').length).toEqual(
          mockData.pipeline.details.stages.length,
        );
      });

      it('should render coverage information', () => {
        expect(vm.$el.querySelector('.media-body').textContent).toContain(
          `Coverage ${mockData.pipeline.coverage}`,
        );
      });
    });

    describe('without coverage', () => {
      it('should not render a coverage', () => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.coverage;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.$el.querySelector('.media-body').textContent).not.toContain('Coverage');
      });
    });

    describe('without a pipeline graph', () => {
      it('should not render a pipeline graph', () => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.details.stages;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.$el.querySelector('.js-mini-pipeline-graph')).toEqual(null);
      });
    });

    describe('without pipeline.merge_request', () => {
      it('should render info that includes the commit and branch details', () => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.merge_request;
        const { pipeline } = mockCopy;

        vm = mountComponent(Component, {
          pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
          sourceBranchLink: mockCopy.source_branch_link,
        });

        const expected = `Pipeline #${pipeline.id} (#${pipeline.iid}) ${
          pipeline.details.status.label
        } for ${pipeline.commit.short_id} on ${mockCopy.source_branch_link}`;

        const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

        expect(actual).toBe(expected);
      });
    });

    describe('with pipeline.merge_request and flags.merge_request_pipeline', () => {
      it('should render info that includes the commit, MR, source branch, and target branch details', () => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        const { pipeline } = mockCopy;
        pipeline.flags.merge_request_pipeline = true;
        pipeline.flags.detached_merge_request_pipeline = false;

        vm = mountComponent(Component, {
          pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
          sourceBranchLink: mockCopy.source_branch_link,
        });

        const expected = `Pipeline #${pipeline.id} (#${pipeline.iid}) ${
          pipeline.details.status.label
        } for ${pipeline.commit.short_id} on !${pipeline.merge_request.iid} with ${
          pipeline.merge_request.source_branch
        } into ${pipeline.merge_request.target_branch}`;

        const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

        expect(actual).toBe(expected);
      });
    });

    describe('with pipeline.merge_request and flags.detached_merge_request_pipeline', () => {
      it('should render info that includes the commit, MR, and source branch details', () => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        const { pipeline } = mockCopy;
        pipeline.flags.merge_request_pipeline = false;
        pipeline.flags.detached_merge_request_pipeline = true;

        vm = mountComponent(Component, {
          pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
          sourceBranchLink: mockCopy.source_branch_link,
        });

        const expected = `Pipeline #${pipeline.id} (#${pipeline.iid}) ${
          pipeline.details.status.label
        } for ${pipeline.commit.short_id} on !${pipeline.merge_request.iid} with ${
          pipeline.merge_request.source_branch
        }`;

        const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

        expect(actual).toBe(expected);
      });
    });
  });
});
