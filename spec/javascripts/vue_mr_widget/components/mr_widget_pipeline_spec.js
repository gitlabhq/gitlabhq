import Vue from 'vue';
import { statusClassToSvgMap } from '~/vue_shared/pipeline_svg_icons';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline';
import pipelineMockData from '../../commit/pipelines/mock_data';

const createComponent = (mr) => {
  const Component = Vue.extend(pipelineComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetPipeline', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = pipelineComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(pipelineComponent.components['pipeline-stage']).toBeDefined();
      expect(pipelineComponent.components['pipeline-status-icon']).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('svg', () => {
      it('should have the proper SVG icon', () => {
        const vm = createComponent({ pipeline: pipelineMockData });

        expect(vm.svg).toEqual(statusClassToSvgMap.icon_status_failed);
      });
    });

    describe('hasCIError', () => {
      it('should return false when there is no CI error', () => {
        const vm = createComponent({
          pipeline: pipelineMockData,
          hasCI: true,
          ciStatus: 'success',
        });

        expect(vm.hasCIError).toBeFalsy();
      });

      it('should return true when there is a CI error', () => {
        const vm = createComponent({
          pipeline: pipelineMockData,
          hasCI: true,
          ciStatus: null,
        });

        expect(vm.hasCIError).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;
    const mr = {
      pipeline: pipelineMockData,
      hasCI: true,
      ciStatus: 'failed',
    };

    beforeEach(() => {
      vm = createComponent(mr);
      el = vm.$el;
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-widget-heading')).toBeTruthy();
      expect(el.querySelectorAll('.ci-status-icon.ci-status-icon-failed').length).toEqual(1);
      expect(el.querySelector('.pipeline-id').textContent).toContain(`#${pipelineMockData.id}`);
      expect(el.innerText).toContain('failed');
      expect(el.querySelector('.pipeline-id').getAttribute('href')).toEqual(pipelineMockData.path);
      expect(el.querySelectorAll('.stage-container').length).toEqual(1);
      expect(el.querySelector('.js-ci-error')).toEqual(null);
      expect(el.querySelector('.js-commit-link').getAttribute('href')).toEqual(pipelineMockData.commit.commit_path);
      expect(el.querySelector('.js-commit-link').textContent).toEqual(pipelineMockData.commit.short_id);
      expect(el.querySelector('.js-mr-coverage').textContent).toContain(`Coverage ${pipelineMockData.coverage}%`);
    });

    it('should list multiple stages', (done) => {
      const [stage] = pipelineMockData.details.stages;
      vm.mr.pipeline.details.stages.push(stage);
      vm.mr.pipeline.details.stages.push(stage);

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.stage-container button').length).toEqual(3);
        done();
      });
    });

    it('should not have stages when there is no stage', (done) => {
      vm.mr.pipeline.details.stages = [];

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.stage-container button').length).toEqual(0);
        done();
      });
    });

    it('should not have coverage text when pipeline has no coverage info', (done) => {
      vm.mr.pipeline.coverage = null;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-mr-coverage')).toEqual(null);
        done();
      });
    });

    it('should show CI error when there is a CI error', (done) => {
      vm.mr.ciStatus = null;

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.js-ci-error').length).toEqual(1);
        expect(el.innerText).toContain('Could not connect to the CI server');
        done();
      });
    });
  });
});
