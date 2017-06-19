import Vue from 'vue';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';
import linkedPipelineJSON from './linked_pipelines_mock_data';

const GraphComponent = Vue.extend(graphComponent);

const pipelineJSON = Object.assign(graphJSON, {
  triggered: linkedPipelineJSON.triggered,
  triggered_by: linkedPipelineJSON.triggered_by,
});

const defaultPropsData = {
  pipeline: pipelineJSON,
  isLoading: false,
};

describe('graph component', function () {
  describe('while is loading', function () {
    beforeEach(function () {
      this.component = new GraphComponent({
        propsData: { pipeline: {}, isLoading: true },
      }).$mount();
    });

    it('should render a loading icon', function () {
      expect(this.component.$el.querySelector('.fa-spinner')).not.toBeNull();
    });
  });

  describe('when linked pipelines are present', function () {
    beforeEach(function () {
      this.component = new GraphComponent({
        propsData: defaultPropsData,
      }).$mount();
    });

    describe('rendered output', function () {
      it('should include the pipelines graph', function () {
        expect(this.component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should not include the loading icon', function () {
        expect(this.component.$el.querySelector('.fa-spinner')).toBeNull();
      });

      it('should include the stage column list', function () {
        expect(this.component.$el.querySelector('.stage-column-list')).not.toBeNull();
      });

      it('should include the no-margin class on the first child', function () {
        const firstStageColumnElement = this.component.$el.querySelector('.stage-column-list .stage-column');
        expect(firstStageColumnElement.classList.contains('no-margin')).toEqual(true);
      });

      it('should include the has-only-one-job class on the first child', function () {
        const firstStageColumnElement = this.component.$el.querySelector('.stage-column-list .stage-column');
        expect(firstStageColumnElement.classList.contains('has-only-one-job')).toEqual(true);
      });

      it('should include the left-margin class on the second child', function () {
        const firstStageColumnElement = this.component.$el.querySelector('.stage-column-list .stage-column:last-child');
        expect(firstStageColumnElement.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the has-linked-pipelines flag', function () {
        expect(this.component.$el.querySelector('.has-linked-pipelines')).not.toBeNull();
      });
    });

    describe('computeds and methods', function () {
      describe('capitalizeStageName', function () {
        it('it capitalizes the stage name', function () {
          expect(this.component.capitalizeStageName('mystage')).toBe('Mystage');
        });
      });

      describe('stageConnectorClass', function () {
        it('it returns left-margin when there is a triggerer', function () {
          expect(this.component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
        });
      });
    });

    describe('linked pipelines components', function () {
      it('should coerce triggeredBy into a collection', function () {
        expect(this.component.triggeredBy.length).toBe(1);
      });

      it('should render an upstream pipelines column', function () {
        expect(this.component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(this.component.$el.innerHTML).toContain('Upstream');
      });

      it('should render a downstream pipelines column', function () {
        expect(this.component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(this.component.$el.innerHTML).toContain('Downstream');
      });
    });
  });

  describe('when linked pipelines are not present', function () {
    beforeEach(function () {
      const pipeline = Object.assign(graphJSON, { triggered: [], triggered_by: [] });
      this.component = new GraphComponent({
        propsData: { pipeline, isLoading: false },
      }).$mount();
    });

    describe('rendered output', function () {
      it('should include the first column with a no margin', function () {
        const firstColumn = this.component.$el.querySelector('.stage-column:first-child');
        expect(firstColumn.classList.contains('no-margin')).toEqual(true);
      });

      it('should not render a linked pipelines column', function () {
        expect(this.component.$el.querySelector('.linked-pipelines-column')).toBeNull();
      });
    });

    describe('stageConnectorClass', function () {
      it('it returns left-margin when no triggerer and there is one job', function () {
        expect(this.component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
      });

      it('it returns left-margin when no triggerer and not the first stage', function () {
        expect(this.component.stageConnectorClass(99, { groups: ['job'] })).toBe('left-margin');
      });
    });
  });
});
