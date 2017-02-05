/* global pipeline, Vue */

require('vue-resource');
require('flash');
require('~/commit/pipelines/pipelines_store');
require('~/commit/pipelines/pipelines_service');
require('~/commit/pipelines/pipelines_table');
require('~vue_shared/vue_resource_interceptor');
require('./mock_data');

describe('Pipelines table in Commits and Merge requests', () => {
  preloadFixtures('pipelines_table');

  beforeEach(() => {
    loadFixtures('pipelines_table');
  });

  describe('successfull request', () => {
    describe('without pipelines', () => {
      const pipelinesEmptyResponse = (request, next) => {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(pipelinesEmptyResponse);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesEmptyResponse,
        );
      });

      it('should render the empty state', (done) => {
        const component = new gl.commits.pipelines.PipelinesTableView({
          el: document.querySelector('#commit-pipeline-table-view'),
        });

        setTimeout(() => {
          expect(component.$el.querySelector('.js-blank-state-title').textContent).toContain('No pipelines to show');
          done();
        }, 1);
      });
    });

    describe('with pipelines', () => {
      const pipelinesResponse = (request, next) => {
        next(request.respondWith(JSON.stringify([pipeline]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(pipelinesResponse);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesResponse,
        );
      });

      it('should render a table with the received pipelines', (done) => {
        const component = new gl.commits.pipelines.PipelinesTableView({
          el: document.querySelector('#commit-pipeline-table-view'),
        });

        setTimeout(() => {
          expect(component.$el.querySelectorAll('table > tbody > tr').length).toEqual(1);
          done();
        }, 0);
      });
    });
  });

  describe('unsuccessfull request', () => {
    const pipelinesErrorResponse = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 500,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(pipelinesErrorResponse);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, pipelinesErrorResponse,
      );
    });

    it('should render empty state', (done) => {
      const component = new gl.commits.pipelines.PipelinesTableView({
        el: document.querySelector('#commit-pipeline-table-view'),
      });

      setTimeout(() => {
        expect(component.$el.querySelector('.js-blank-state-title').textContent).toContain('No pipelines to show');
        done();
      }, 0);
    });
  });
});
