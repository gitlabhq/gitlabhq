import Vue from 'vue';
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

  describe('template', () => {
    let vm;
    let el;
    const mr = {
      pipeline: pipelineMockData,
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
  });
});
