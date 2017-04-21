import Vue from 'vue';
import PipelinesTable from '~/commit/pipelines/pipelines_table';
import pipeline from './mock_data';

describe('Pipelines table in Commits and Merge requests', () => {
  preloadFixtures('static/pipelines_table.html.raw');

  beforeEach(() => {
    loadFixtures('static/pipelines_table.html.raw');
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      const pipelinesEmptyResponse = (request, next) => {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      };

      beforeEach(function () {
        Vue.http.interceptors.push(pipelinesEmptyResponse);

        this.component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });
      });

      afterEach(function () {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesEmptyResponse,
        );
        this.component.$destroy();
      });

      it('should render the empty state', function (done) {
        setTimeout(() => {
          expect(this.component.$el.querySelector('.empty-state')).toBeDefined();
          expect(this.component.$el.querySelector('.realtime-loading')).toBe(null);
          expect(this.component.$el.querySelector('.js-pipelines-error-state')).toBe(null);
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

        this.component = new PipelinesTable({
          el: document.querySelector('#commit-pipeline-table-view'),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesResponse,
        );
        this.component.$destroy();
      });

      it('should render a table with the received pipelines', (done) => {
        setTimeout(() => {
          expect(this.component.$el.querySelectorAll('table > tbody > tr').length).toEqual(1);
          expect(this.component.$el.querySelector('.realtime-loading')).toBe(null);
          expect(this.component.$el.querySelector('.empty-state')).toBe(null);
          expect(this.component.$el.querySelector('.js-pipelines-error-state')).toBe(null);
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

    beforeEach(function () {
      Vue.http.interceptors.push(pipelinesErrorResponse);

      this.component = new PipelinesTable({
        el: document.querySelector('#commit-pipeline-table-view'),
      });
    });

    afterEach(function () {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, pipelinesErrorResponse,
      );
      this.component.$destroy();
    });

    it('should render error state', function (done) {
      setTimeout(() => {
        expect(this.component.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        expect(this.component.$el.querySelector('.realtime-loading')).toBe(null);
        expect(this.component.$el.querySelector('.js-empty-state')).toBe(null);
        expect(this.component.$el.querySelector('table')).toBe(null);
        done();
      }, 0);
    });
  });
});
