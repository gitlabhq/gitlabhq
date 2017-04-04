/* global pipeline, Vue */

const PipelinesTable = require('~/commit/pipelines/pipelines_table');

require('~/flash');
require('~/commit/pipelines/pipelines_store');
require('~/commit/pipelines/pipelines_service');
require('~/vue_shared/vue_resource_interceptor');
const pipeline = require('./mock_data');

describe('Pipelines table in Commits and Merge requests', () => {
  preloadFixtures('static/pipelines_table.html.raw');

  let component;

  beforeEach(() => {
    loadFixtures('static/pipelines_table.html.raw');
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

        component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesEmptyResponse,
        );
        component.$destroy();
      });

      it('should render the empty state', (done) => {
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

        component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesResponse,
        );
        component.$destroy();
      });

      it('should render a table with the received pipelines', (done) => {
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

      component = new PipelinesTable({
        el: document.querySelector('#commit-pipeline-table-view'),
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, pipelinesErrorResponse,
      );
      component.$destroy();
    });

    it('should render empty state', (done) => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-blank-state-title').textContent).toContain('No pipelines to show');
        done();
      }, 0);
    });
  });
});
