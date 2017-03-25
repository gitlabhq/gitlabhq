import Vue from 'vue';
import VueResource from 'vue-resource';
import Poll from '~/lib/utils/poll';

Vue.use(VueResource);

class ServiceMock {
  constructor(endpoint) {
    this.service = Vue.resource(endpoint);
  }

  fetch() {
    return this.service.get();
  }
}

describe('Poll', () => {
  let callbacks;

  beforeEach(() => {
    callbacks = {
      success: () => {},
      error: () => {},
    };

    spyOn(callbacks, 'success');
    spyOn(callbacks, 'error');
  });

  it('calls the success callback when no header for interval is provided', (done) => {
    const successInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200 }));
    };

    Vue.http.interceptors.push(successInterceptor);

    new Poll({
      resource: new ServiceMock('endpoint'),
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    setTimeout(() => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
      done();
    }, 0);

    Vue.http.interceptors = _.without(Vue.http.interceptors, successInterceptor);
  });

  it('calls the error callback whe the http request returns an error', (done) => {
    const errorInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 500 }));
    };

    Vue.http.interceptors.push(errorInterceptor);

    new Poll({
      resource: new ServiceMock('endpoint'),
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    setTimeout(() => {
      expect(callbacks.success).not.toHaveBeenCalled();
      expect(callbacks.error).toHaveBeenCalled();
      done();
    }, 0);

    Vue.http.interceptors = _.without(Vue.http.interceptors, errorInterceptor);
  });

  it('should call the success callback when the interval header is -1', (done) => {
    const intervalInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': -1 } }));
    };

    Vue.http.interceptors.push(intervalInterceptor);

    new Poll({
      resource: new ServiceMock('endpoint'),
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    setTimeout(() => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
      done();
    }, 0);

    Vue.http.interceptors = _.without(Vue.http.interceptors, intervalInterceptor);
  });

  it('starts polling when http status is 200 and interval header is provided', (done) => {
    const pollInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': 2 } }));
    };

    Vue.http.interceptors.push(pollInterceptor);

    const service = new ServiceMock('endpoint');
    spyOn(service, 'fetch').and.callThrough();

    new Poll({
      resource: service,
      method: 'fetch',
      data: { page: 1 },
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    setTimeout(() => {
      expect(service.fetch.calls.count()).toEqual(2);
      expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
      done();
    }, 5);

    Vue.http.interceptors = _.without(Vue.http.interceptors, pollInterceptor);
  });

  describe('stop', () => {
    it('stops polling when method is called', (done) => {
      const pollInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': 2 } }));
      };

      Vue.http.interceptors.push(pollInterceptor);

      const service = new ServiceMock('endpoint');
      spyOn(service, 'fetch').and.callThrough();

      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: () => {
          Polling.stop();
        },
        errorCallback: callbacks.error,
      });

      spyOn(Polling, 'stop').and.callThrough();

      Polling.makeRequest();

      setTimeout(() => {
        expect(service.fetch.calls.count()).toEqual(1);
        expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
        expect(Polling.stop).toHaveBeenCalled();
        done();
      }, 100);

      Vue.http.interceptors = _.without(Vue.http.interceptors, pollInterceptor);
    });
  });
});
