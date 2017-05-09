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
    const graphJSON = {
      details: {
        stages: [{
          name: 'review',
          title: 'review: passed',
          groups: [{
            name: 'review_1',
            size: 1,
            status: {
              icon: 'icon_status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              has_details: true,
              details_path: '/root/review-app/builds/4374',
              favicon: '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
              action: {
                icon: 'icon_action_retry',
                title: 'Retry',
                path: '/root/review-app/builds/4374/retry',
                method: 'post',
              },
            },
            jobs: [{
              id: 4374,
              name: 'review_1',
              build_path: '/root/review-app/builds/4374',
              retry_path: '/root/review-app/builds/4374/retry',
              playable: false,
              created_at: '2017-05-08T14:57:39.880Z',
              updated_at: '2017-05-08T14:57:52.639Z',
              status: {
                icon: 'icon_status_success',
                text: 'passed',
                label: 'passed',
                group: 'success',
                has_details: true,
                details_path: '/root/review-app/builds/4374',
                favicon: '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
                action: {
                  icon: 'icon_action_retry',
                  title: 'Retry',
                  path: '/root/review-app/builds/4374/retry',
                  method: 'post',
                },
              },
            }],
          }],
        }],
      },
    };

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

        expect(component.$el.querySelector('loading-icon')).toBe(null);

        expect(component.$el.querySelector('.stage-column-list')).toBeDefined();
        done();
      }, 0);
    });
  });
});
