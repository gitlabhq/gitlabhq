import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import pipelineJSON from 'spec/pipelines/graph/mock_data';
import linkedPipelineJSON from 'spec/pipelines/graph/linked_pipelines_mock_data';

const graphJSON = Object.assign(pipelineJSON, {
  triggered: linkedPipelineJSON.triggered,
  triggered_by: linkedPipelineJSON.triggered_by,
});

describe('graph component', () => {
  const GraphComponent = Vue.extend(graphComponent);
  let component;

  afterEach(() => {
    component.$destroy();
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      component = mountComponent(GraphComponent, {
        isLoading: true,
        pipeline: {},
      });

      expect(component.$el.querySelector('.loading-icon')).toBeDefined();
    });
  });

  describe('when linked pipelines are present', function () {
    beforeEach(function () {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
      });
    });

    describe('rendered output', function () {
      it('should include the pipelines graph', function () {
        expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should not include the loading icon', function () {
        expect(component.$el.querySelector('.fa-spinner')).toBeNull();
      });

      it('should include the stage column list', function () {
        expect(component.$el.querySelector('.stage-column-list')).not.toBeNull();
      });

      it('should include the no-margin class on the first child', function () {
        const firstStageColumnElement = component.$el.querySelector('.stage-column-list .stage-column');
        expect(firstStageColumnElement.classList.contains('no-margin')).toEqual(true);
      });

      it('should include the has-only-one-job class on the first child', function () {
        const firstStageColumnElement = component.$el.querySelector('.stage-column-list .stage-column');
        expect(firstStageColumnElement.classList.contains('has-only-one-job')).toEqual(true);
      });

      it('should include the left-margin class on the second child', function () {
        const firstStageColumnElement = component.$el.querySelector('.stage-column-list .stage-column:last-child');
        expect(firstStageColumnElement.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the has-linked-pipelines flag', function () {
        expect(component.$el.querySelector('.has-linked-pipelines')).not.toBeNull();
      });
    });

    describe('computeds and methods', function () {
      describe('capitalizeStageName', function () {
        it('it capitalizes the stage name', function () {
          expect(component.capitalizeStageName('mystage')).toBe('Mystage');
        });
      });

      describe('stageConnectorClass', function () {
        it('it returns left-margin when there is a triggerer', function () {
          expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
        });
      });
    });

    describe('linked pipelines components', function () {
      it('should coerce triggeredBy into a collection', function () {
        expect(component.triggeredBy.length).toBe(1);
      });

      it('should render an upstream pipelines column', function () {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Upstream');
      });

      it('should render a downstream pipelines column', function () {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Downstream');
      });
    });
  });

  describe('when linked pipelines are not present', function () {
    beforeEach(function () {
      const pipeline = Object.assign(graphJSON, { triggered: null, triggered_by: null });
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline,
      });
    });

    describe('rendered output', function () {
      it('should include the first column with a no margin', function () {
        const firstColumn = component.$el.querySelector('.stage-column:first-child');
        expect(firstColumn.classList.contains('no-margin')).toEqual(true);
      });

      it('should not render a linked pipelines column', function () {
        expect(component.$el.querySelector('.linked-pipelines-column')).toBeNull();
      });
    });

    describe('stageConnectorClass', function () {
      it('it returns left-margin when no triggerer and there is one job', function () {
        expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
      });

      it('it returns left-margin when no triggerer and not the first stage', function () {
        expect(component.stageConnectorClass(99, { groups: ['job'] })).toBe('left-margin');
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
      });

      expect(component.$el.querySelector('.stage-column:nth-child(2) .stage-name').textContent.trim()).toEqual('Deploy &lt;img src=x onerror=alert(document.domain)&gt;');
    });
  });
});
