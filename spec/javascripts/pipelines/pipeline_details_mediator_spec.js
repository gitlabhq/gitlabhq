import _ from 'underscore';
import Vue from 'vue';
import PipelineMediator from '~/pipelines/pipeline_details_mediator';
<<<<<<< HEAD
import { sastIssues, parsedSastIssuesStore } from '../vue_shared/security_reports/mock_data';
=======
>>>>>>> upstream/master

describe('PipelineMdediator', () => {
  let mediator;
  beforeEach(() => {
    mediator = new PipelineMediator({ endpoint: 'foo' });
  });

  it('should set defaults', () => {
    expect(mediator.options).toEqual({ endpoint: 'foo' });
    expect(mediator.state.isLoading).toEqual(false);
    expect(mediator.store).toBeDefined();
    expect(mediator.service).toBeDefined();
  });

  describe('request and store data', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({ foo: 'bar' }), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptor, interceptor);
    });

    it('should store received data', (done) => {
      mediator.fetchPipeline();

      setTimeout(() => {
        expect(mediator.store.state.pipeline).toEqual({ foo: 'bar' });
        done();
      });
    });
  });

  describe('security reports', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(sastIssues), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptor, interceptor);
    });

    it('fetches the requests endpoint and stores the data', (done) => {
      mediator.fetchSastReport('sast.json', 'path');

      setTimeout(() => {
        expect(mediator.store.state.securityReports.sast.newIssues).toEqual(parsedSastIssuesStore);
        done();
      }, 0);
    });
  });
});
