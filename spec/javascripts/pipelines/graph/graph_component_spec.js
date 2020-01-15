import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import PipelineStore from '~/pipelines/stores/pipeline_store';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';
import linkedPipelineJSON from '../linked_pipelines_mock.json';
import PipelinesMediator from '~/pipelines/pipeline_details_mediator';

describe('graph component', () => {
  const GraphComponent = Vue.extend(graphComponent);
  const store = new PipelineStore();
  store.storePipeline(linkedPipelineJSON);
  const mediator = new PipelinesMediator({ endpoint: '' });

  let component;

  beforeEach(() => {
    setFixtures(`
      <div class="layout-page"></div>
    `);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      component = mountComponent(GraphComponent, {
        isLoading: true,
        pipeline: {},
        mediator,
      });

      expect(component.$el.querySelector('.loading-icon')).toBeDefined();
    });
  });

  describe('with data', () => {
    it('should render the graph', () => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
        mediator,
      });

      expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);

      expect(
        component.$el.querySelector('.stage-column:first-child').classList.contains('no-margin'),
      ).toEqual(true);

      expect(
        component.$el.querySelector('.stage-column:nth-child(2)').classList.contains('left-margin'),
      ).toEqual(true);

      expect(
        component.$el
          .querySelector('.stage-column:nth-child(2) .build:nth-child(1)')
          .classList.contains('left-connector'),
      ).toEqual(true);

      expect(component.$el.querySelector('loading-icon')).toBe(null);

      expect(component.$el.querySelector('.stage-column-list')).toBeDefined();
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: store.state.pipeline,
        mediator,
      });
    });

    describe('rendered output', () => {
      it('should include the pipelines graph', () => {
        expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should not include the loading icon', () => {
        expect(component.$el.querySelector('.fa-spinner')).toBeNull();
      });

      it('should include the stage column list', () => {
        expect(component.$el.querySelector('.stage-column-list')).not.toBeNull();
      });

      it('should include the no-margin class on the first child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column',
        );

        expect(firstStageColumnElement.classList.contains('no-margin')).toEqual(true);
      });

      it('should include the has-only-one-job class on the first child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column',
        );

        expect(firstStageColumnElement.classList.contains('has-only-one-job')).toEqual(true);
      });

      it('should include the left-margin class on the second child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column:last-child',
        );

        expect(firstStageColumnElement.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the js-has-linked-pipelines flag', () => {
        expect(component.$el.querySelector('.js-has-linked-pipelines')).not.toBeNull();
      });
    });

    describe('computeds and methods', () => {
      describe('capitalizeStageName', () => {
        it('it capitalizes the stage name', () => {
          expect(component.capitalizeStageName('mystage')).toBe('Mystage');
        });
      });

      describe('stageConnectorClass', () => {
        it('it returns left-margin when there is a triggerer', () => {
          expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
        });
      });
    });

    describe('linked pipelines components', () => {
      beforeEach(() => {
        component = mountComponent(GraphComponent, {
          isLoading: false,
          pipeline: store.state.pipeline,
          mediator,
        });
      });

      it('should render an upstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Upstream');
      });

      it('should render a downstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Downstream');
      });

      describe('triggered by', () => {
        describe('on click', () => {
          it('should emit `onClickTriggeredBy` when triggered by linked pipeline is clicked', () => {
            spyOn(component, '$emit');

            component.$el.querySelector('#js-linked-pipeline-12').click();

            expect(component.$emit).toHaveBeenCalledWith(
              'onClickTriggeredBy',
              component.pipeline,
              component.pipeline.triggered_by[0],
            );
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', done => {
            // expand the pipeline
            store.state.pipeline.triggered_by[0].isExpanded = true;

            component = mountComponent(GraphComponent, {
              isLoading: false,
              pipeline: store.state.pipeline,
              mediator,
            });

            Vue.nextTick()
              .then(() => {
                expect(component.$el.querySelector('.js-upstream-pipeline-12')).not.toBeNull();
              })
              .then(done)
              .catch(done.fail);
          });
        });
      });

      describe('triggered', () => {
        describe('on click', () => {
          it('should emit `onClickTriggered`', () => {
            spyOn(component, '$emit');
            spyOn(component, 'calculateMarginTop').and.callFake(() => '16px');

            component.$el.querySelector('#js-linked-pipeline-34993051').click();

            expect(component.$emit).toHaveBeenCalledWith(
              'onClickTriggered',
              component.pipeline,
              component.pipeline.triggered[0],
            );
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', done => {
            // expand the pipeline
            store.state.pipeline.triggered[0].isExpanded = true;

            component = mountComponent(GraphComponent, {
              isLoading: false,
              pipeline: store.state.pipeline,
              mediator,
            });

            Vue.nextTick()
              .then(() => {
                expect(
                  component.$el.querySelector('.js-downstream-pipeline-34993051'),
                ).not.toBeNull();
              })
              .then(done)
              .catch(done.fail);
          });
        });
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      const pipeline = Object.assign(linkedPipelineJSON, { triggered: null, triggered_by: null });
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline,
        mediator,
      });
    });

    describe('rendered output', () => {
      it('should include the first column with a no margin', () => {
        const firstColumn = component.$el.querySelector('.stage-column:first-child');

        expect(firstColumn.classList.contains('no-margin')).toEqual(true);
      });

      it('should not render a linked pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).toBeNull();
      });
    });

    describe('stageConnectorClass', () => {
      it('it returns left-margin when no triggerer and there is one job', () => {
        expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
      });

      it('it returns left-margin when no triggerer and not the first stage', () => {
        expect(component.stageConnectorClass(99, { groups: ['job'] })).toBe('left-margin');
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
        mediator,
      });

      expect(
        component.$el.querySelector('.stage-column:nth-child(2) .stage-name').textContent.trim(),
      ).toEqual('Deploy &lt;img src=x onerror=alert(document.domain)&gt;');
    });
  });
});
