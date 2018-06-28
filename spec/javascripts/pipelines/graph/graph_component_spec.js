import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';

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

  describe('with data', () => {
    it('should render the graph', () => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
      });

      expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);

      expect(
        component.$el.querySelector('.stage-column:first-child').classList.contains('no-margin'),
      ).toEqual(true);

      expect(
        component.$el.querySelector('.stage-column:nth-child(2)').classList.contains('left-margin'),
      ).toEqual(true);

      expect(
        component.$el.querySelector('.stage-column:nth-child(2) .build:nth-child(1)').classList.contains('left-connector'),
      ).toEqual(true);

      expect(component.$el.querySelector('loading-icon')).toBe(null);

      expect(component.$el.querySelector('.stage-column-list')).toBeDefined();
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
