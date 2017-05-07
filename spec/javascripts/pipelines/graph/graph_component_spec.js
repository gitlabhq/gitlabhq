import Vue from 'vue';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';

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
      next(request.respondWith(JSON.stringify({
        details: {
          stages: [{
            name: 'test',
            title: 'test: passed',
            status: {
              icon: 'icon_status_success',
              text: 'passed',
              label: 'passed',
              details_path: '/root/ci-mock/pipelines/123#test',
            },
            path: '/root/ci-mock/pipelines/123#test',
            groups: [{
              name: 'test',
              size: 1,
              jobs: [{
                id: 4153,
                name: 'test',
                status: {
                  icon: 'icon_status_success',
                  text: 'passed',
                  label: 'passed',
                  details_path: '/root/ci-mock/builds/4153',
                  action: {
                    icon: 'icon_action_retry',
                    title: 'Retry',
                    path: '/root/ci-mock/builds/4153/retry',
                    method: 'post',
                  },
                },
              }],
            }],
          }],
        },
      }), {
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

        expect(component.$el.querySelector('loading-icon')).toBe(null);

        expect(component.$el.querySelector('.stage-column-list')).toBeDefined();
        done();
      }, 0);
    });
  });
});
