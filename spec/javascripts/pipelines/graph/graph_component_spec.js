import Vue from 'vue';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import graphJSON from './mock_data';

describe('graph component', () => {
  preloadFixtures('static/graph.html.raw');

  let GraphComponent;

  beforeEach(() => {
    loadFixtures('static/graph.html.raw');
    GraphComponent = Vue.extend(graphComponent);
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');
      expect(component.$el.querySelector('.loading-icon')).toBeDefined();
    });
  });

  describe('with a successfull response', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(graphJSON), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should render the graph', (done) => {
      const component = new GraphComponent().$mount('#js-pipeline-graph-vue');

      setTimeout(() => {
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
        done();
      }, 0);
    });
  });
});
