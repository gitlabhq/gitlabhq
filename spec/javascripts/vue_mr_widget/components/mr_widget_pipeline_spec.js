import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/text_helper';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
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

    describe('coverageDeltaClass', () => {
      it('should return no class if there is no coverage change', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          pipelineCoverageDelta: '0',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.coverageDeltaClass).toEqual('');
      });

      it('should return text-success if the coverage increased', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          pipelineCoverageDelta: '10',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.coverageDeltaClass).toEqual('text-success');
      });

      it('should return text-danger if the coverage decreased', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          pipelineCoverageDelta: '-12',
          troubleshootingDocsPath: 'help',
        });

        expect(vm.coverageDeltaClass).toEqual('text-danger');
      });
    });
  });

  describe('rendered output', () => {
    it('should render CI error', () => {
      vm = mountComponent(Component, {
        pipeline: mockData.pipeline,
        hasCi: true,
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
          pipelineCoverageDelta: mockData.pipelineCoverageDelta,
          troubleshootingDocsPath: 'help',
        });
      });

      it('should render pipeline ID', () => {
        expect(vm.$el.querySelector('.pipeline-id').textContent.trim()).toEqual(
          `#${mockData.pipeline.id}`,
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

      it('should render pipeline coverage delta information', () => {
        expect(vm.$el.querySelector('.js-pipeline-coverage-delta.text-danger')).toBeDefined();
        expect(vm.$el.querySelector('.js-pipeline-coverage-delta').textContent).toContain(
          `(${mockData.pipelineCoverageDelta}%)`,
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
          `#${mockData.pipeline.id}`,
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

    describe('for each type of pipeline', () => {
      let pipeline;

      beforeEach(() => {
        ({ pipeline } = JSON.parse(JSON.stringify(mockData)));

        pipeline.details.name = 'Pipeline';
        pipeline.merge_request_event_type = undefined;
        pipeline.ref.tag = false;
        pipeline.ref.branch = false;
      });

      const factory = () => {
        vm = mountComponent(Component, {
          pipeline,
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
          sourceBranchLink: mockData.source_branch_link,
        });
      };

      describe('for a branch pipeline', () => {
        it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
          pipeline.ref.branch = true;

          factory();

          const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id} on ${mockData.source_branch_link}`;
          const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

          expect(actual).toBe(expected);
        });
      });

      describe('for a tag pipeline', () => {
        it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
          pipeline.ref.tag = true;

          factory();

          const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
          const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

          expect(actual).toBe(expected);
        });
      });

      describe('for a detached merge request pipeline', () => {
        it('renders a pipeline widget that reads "Detached merge request pipeline <ID> <status> for <SHA>"', () => {
          pipeline.details.name = 'Detached merge request pipeline';
          pipeline.merge_request_event_type = 'detached';

          factory();

          const expected = `Detached merge request pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
          const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

          expect(actual).toBe(expected);
        });
      });
    });
  });
});
