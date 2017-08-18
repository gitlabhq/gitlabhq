import Vue from 'vue';
import JobMediator from '~/jobs/job_details_mediator';
import job from './mock_data';

describe('JobMediator', () => {
  let mediator;

  beforeEach(() => {
    mediator = new JobMediator({ endpoint: 'foo' });
  });

  it('should set defaults', () => {
    expect(mediator.store).toBeDefined();
    expect(mediator.service).toBeDefined();
    expect(mediator.options).toEqual({ endpoint: 'foo' });
    expect(mediator.state.isLoading).toEqual(false);
  });

  describe('request and store data', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(job), {
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
      mediator.fetchJob();

      setTimeout(() => {
        expect(mediator.store.state.job).toEqual(job);
        done();
      }, 0);
    });
  });
});
