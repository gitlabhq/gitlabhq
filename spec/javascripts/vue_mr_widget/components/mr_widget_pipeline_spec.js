import Vue from 'vue';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper'; // eslint-disable-line import/first
import mockData from '../mock_data';
import mockLinkedPipelines from 'spec/pipelines/graph/linked_pipelines_mock_data'; // eslint-disable-line import/first

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
        });

        expect(vm.hasPipeline).toEqual(true);
      });

      it('should return false when there is no pipeline', () => {
        vm = mountComponent(Component, {
          pipeline: {},
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
        });

        expect(vm.hasCIError).toEqual(false);
      });

      it('should return true when there is a CI error', () => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          hasCi: true,
          ciStatus: null,
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
      });

      expect(
        vm.$el.querySelector('.media-body').textContent.trim(),
      ).toEqual('Could not connect to the CI server. Please check your settings and try again');
    });

    describe('with a pipeline', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: mockData.pipeline,
          hasCi: true,
          ciStatus: 'success',
        });
      });

      it('should render pipeline ID', () => {
        expect(
          vm.$el.querySelector('.pipeline-id').textContent.trim(),
        ).toEqual(`#${mockData.pipeline.id}`);
      });

      it('should render pipeline status and commit id', () => {
        expect(
          vm.$el.querySelector('.media-body').textContent.trim(),
        ).toContain(mockData.pipeline.details.status.label);

        expect(
          vm.$el.querySelector('.js-commit-link').textContent.trim(),
        ).toEqual(mockData.pipeline.commit.short_id);

        expect(
          vm.$el.querySelector('.js-commit-link').getAttribute('href'),
        ).toEqual(mockData.pipeline.commit.commit_path);
      });

      it('should render pipeline graph', () => {
        expect(vm.$el.querySelector('.mr-widget-pipeline-graph')).toBeDefined();
        expect(vm.$el.querySelectorAll('.stage-container').length).toEqual(mockData.pipeline.details.stages.length);
      });

      it('should render coverage information', () => {
        expect(
          vm.$el.querySelector('.media-body').textContent,
        ).toContain(`Coverage ${mockData.pipeline.coverage}`);
      });
    });

    describe('without commit path', () => {
      beforeEach(() => {
        const mockCopy = Object.assign({}, mockData);
        delete mockCopy.pipeline.commit;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
        });
      });

      it('should render pipeline ID', () => {
        expect(
          vm.$el.querySelector('.pipeline-id').textContent.trim(),
        ).toEqual(`#${mockData.pipeline.id}`);
      });

      it('should render pipeline status', () => {
        expect(
          vm.$el.querySelector('.media-body').textContent.trim(),
        ).toContain(mockData.pipeline.details.status.label);

        expect(
          vm.$el.querySelector('.js-commit-link'),
        ).toBeNull();
      });

      it('should render pipeline graph', () => {
        expect(vm.$el.querySelector('.mr-widget-pipeline-graph')).toBeDefined();
        expect(vm.$el.querySelectorAll('.stage-container').length).toEqual(mockData.pipeline.details.stages.length);
      });

      it('should render coverage information', () => {
        expect(
          vm.$el.querySelector('.media-body').textContent,
        ).toContain(`Coverage ${mockData.pipeline.coverage}`);
      });
    });

    describe('without coverage', () => {
      it('should not render a coverage', () => {
        const mockCopy = Object.assign({}, mockData);
        delete mockCopy.pipeline.coverage;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
        });

        expect(
          vm.$el.querySelector('.media-body').textContent,
        ).not.toContain('Coverage');
      });
    });

    describe('without a pipeline graph', () => {
      it('should not render a pipeline graph', () => {
        const mockCopy = Object.assign({}, mockData);
        delete mockCopy.pipeline.details.stages;

        vm = mountComponent(Component, {
          pipeline: mockCopy.pipeline,
          hasCi: true,
          ciStatus: 'success',
        });

        expect(vm.$el.querySelector('.js-mini-pipeline-graph')).toEqual(null);
      });
    });

    describe('when upstream pipelines are passed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: Object.assign({}, mockData.pipeline, {
            triggered_by: mockLinkedPipelines.triggered_by,
          }),
          hasCi: true,
          ciStatus: 'success',
        });
      });

      it('should coerce triggeredBy into a collection', () => {
        expect(vm.triggeredBy.length).toBe(1);
      });

      it('should render the linked pipelines mini list', () => {
        expect(vm.$el.querySelector('.linked-pipeline-mini-list.is-upstream')).not.toBeNull();
      });
    });

    describe('when downstream pipelines are passed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: Object.assign({}, mockData.pipeline, {
            triggered: mockLinkedPipelines.triggered,
          }),
          hasCi: true,
          ciStatus: 'success',
        });
      });

      it('should render the linked pipelines mini list', () => {
        expect(vm.$el.querySelector('.linked-pipeline-mini-list.is-downstream')).not.toBeNull();
      });
    });
  });
});
