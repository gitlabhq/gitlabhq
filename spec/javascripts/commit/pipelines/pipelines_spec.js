import Vue from 'vue';
import PipelinesTable from '~/commit/pipelines/pipelines_table';
import pipeline from './mock_data';

describe('Pipelines table in Commits and Merge requests', () => {
  preloadFixtures('static/pipelines_table.html.raw');

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
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesEmptyResponse,
        );
      });

      it('should render the empty state', (done) => {
        const component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });

        setTimeout(() => {
          expect(component.$el.querySelector('.empty-state')).toBeDefined();
          expect(component.$el.querySelector('.realtime-loading')).toBe(null);
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
        const component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });

        setTimeout(() => {
          expect(component.$el.querySelectorAll('table > tbody > tr').length).toEqual(1);
          expect(component.$el.querySelector('.realtime-loading')).toBe(null);
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
      const component = new PipelinesTable({
        el: document.querySelector('#commit-pipeline-table-view'),
      });

      setTimeout(() => {
        expect(component.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        expect(component.$el.querySelector('.realtime-loading')).toBe(null);
        done();
      }, 0);
    });
  });
});
