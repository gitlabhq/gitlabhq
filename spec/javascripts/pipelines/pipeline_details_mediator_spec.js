import _ from 'underscore';
import Vue from 'vue';
import PipelineMediator from '~/pipelines/pipeline_details_mediator';

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
});
