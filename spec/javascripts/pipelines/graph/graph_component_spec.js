import Vue from 'vue';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';
import linkedPipelineJSON from './linked_pipelines_mock_data';

const GraphComponent = Vue.extend(graphComponent);

const state = {
  graph: graphJSON.details.stages,
  triggered: linkedPipelineJSON.triggered,
  triggerer: linkedPipelineJSON.triggerer,
};

describe('graph component', function () {
  describe('while is loading', function () {
    beforeEach(function () {
      this.component = new GraphComponent({
        propsData: { state },
      }).$mount();
    });

    it('should render a loading icon', function () {
      expect(this.component.$el.querySelector('.loading-icon')).not.toBeNull();
    });
  });

  describe('when linked pipelines are present', function () {
    beforeEach(function () {
      this.component = new GraphComponent({
        propsData: { state },
      }).$mount();
    });

    describe('rendered output', function () {
      it('should include the pipelines graph', function () {
        expect(this.component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should include the first column with left margin', function () {
        const firstColumn = this.component.$el.querySelector('.stage-column:first-child');
        expect(firstColumn.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the second column with a left margin', function () {
        const secondColumn = this.component.$el.querySelector('.stage-column:nth-child(2)');
        expect(secondColumn.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the second column first build with a left connector', function () {
        const firstBuild = this.component.$el.querySelector('.stage-column:nth-child(2) .build:nth-child(1)');
        expect(firstBuild.classList.contains('left-connector')).toEqual(true);
      });

      it('should not include the loading icon', function () {
        expect(this.component.$el.querySelector('.loading-icon')).toBe(null);
      });

      it('should include the stage column list', function () {
        expect(this.component.$el.querySelector('.stage-column-list')).toBeDefined();
      });

      it('should include the has-linked-pipelines flag', function () {
        expect(this.component.$el.querySelector('.has-linked-pipelines')).toBeDefined();
      });
    });

    describe('computeds and methods', function () {
      it('linkedPipelinesClass should return "has-linked-pipelines"', function () {
        expect(this.component.linkedPipelinesClass).toBe('has-linked-pipelines');
      });

      describe('capitalizeStageName', function () {
        it('it capitalizes the stage name', function () {
          expect(this.component.capitalizeStageName('mystage')).toBe('Mystage');
        });
      });

      describe('stageConnectorClass', function () {
        it('it returns left-margin when there is a triggerer', function () {
          expect(this.component.stageConnectorClass(0, { groups: ['job'] })).toBe('left-margin');
        });
      });

      describe('linkedPipelineClass', function () {
        it('it returns has-upstream when triggerer and first stage', function () {
          expect(this.component.linkedPipelineClass(0)).toBe('has-upstream');
        });

        it('it returns has-downstream when triggered and is last stage', function () {
          expect(this.component.linkedPipelineClass(1)).toBe('has-downstream');
        });
      });
    });

    describe('linked pipelines components', function () {
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
      this.component = new GraphComponent({
        propsData: { state: Object.assign(state, { triggered: [], triggerer: [] }) },
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

    describe('linkedPipelineClass', function () {
      it('it returns empty string when no triggerer', function () {
        expect(this.component.linkedPipelineClass(1)).toBe('');
      });
    });
  });
});
