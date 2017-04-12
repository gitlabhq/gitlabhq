import Vue from 'vue';
import VueResource from 'vue-resource';
import Poll from '~/lib/utils/poll';

Vue.use(VueResource);

const waitForAllCallsToFinish = (service, waitForCount, successCallback) => {
  const timer = () => {
    setTimeout(() => {
      if (service.fetch.calls.count() === waitForCount) {
        successCallback();
      } else {
        timer();
      }
    }, 5);
  };

  timer();
};

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
  let service;

  beforeEach(() => {
    callbacks = {
      success: () => {},
      error: () => {},
    };

    service = new ServiceMock('endpoint');

    spyOn(callbacks, 'success');
    spyOn(callbacks, 'error');
    spyOn(service, 'fetch').and.callThrough();
  });

  it('calls the success callback when no header for interval is provided', (done) => {
    const successInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200 }));
    };

    Vue.http.interceptors.push(successInterceptor);

    new Poll({
      resource: service,
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    waitForAllCallsToFinish(service, 1, () => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();

      Vue.http.interceptors = _.without(Vue.http.interceptors, successInterceptor);

      done();
    }, 0);
  });

  it('calls the error callback whe the http request returns an error', (done) => {
    const errorInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 500 }));
    };

    Vue.http.interceptors.push(errorInterceptor);

    new Poll({
      resource: service,
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    waitForAllCallsToFinish(service, 1, () => {
      expect(callbacks.success).not.toHaveBeenCalled();
      expect(callbacks.error).toHaveBeenCalled();
      Vue.http.interceptors = _.without(Vue.http.interceptors, errorInterceptor);

      done();
    });
  });

  it('should call the success callback when the interval header is -1', (done) => {
    const intervalInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': -1 } }));
    };

    Vue.http.interceptors.push(intervalInterceptor);

    new Poll({
      resource: service,
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    }).makeRequest();

    setTimeout(() => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();

      Vue.http.interceptors = _.without(Vue.http.interceptors, intervalInterceptor);

      done();
    }, 0);
  });

  it('starts polling when http status is 200 and interval header is provided', (done) => {
    const pollInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': 2 } }));
    };

    Vue.http.interceptors.push(pollInterceptor);

    const Polling = new Poll({
      resource: service,
      method: 'fetch',
      data: { page: 1 },
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
    });

    Polling.makeRequest();

    waitForAllCallsToFinish(service, 2, () => {
      Polling.stop();

      expect(service.fetch.calls.count()).toEqual(2);
      expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();

      Vue.http.interceptors = _.without(Vue.http.interceptors, pollInterceptor);

      done();
    });
  });

  describe('stop', () => {
    it('stops polling when method is called', (done) => {
      const pollInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': 2 } }));
      };

      Vue.http.interceptors.push(pollInterceptor);

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

      waitForAllCallsToFinish(service, 1, () => {
        expect(service.fetch.calls.count()).toEqual(1);
        expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
        expect(Polling.stop).toHaveBeenCalled();

        Vue.http.interceptors = _.without(Vue.http.interceptors, pollInterceptor);

        done();
      });
    });
  });

  describe('restart', () => {
    it('should restart polling when its called', (done) => {
      const pollInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), { status: 200, headers: { 'poll-interval': 2 } }));
      };

      Vue.http.interceptors.push(pollInterceptor);

      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: () => {
          Polling.stop();
          setTimeout(() => {
            Polling.restart();
          }, 0);
        },
        errorCallback: callbacks.error,
      });

      spyOn(Polling, 'stop').and.callThrough();
      spyOn(Polling, 'restart').and.callThrough();

      Polling.makeRequest();

      waitForAllCallsToFinish(service, 2, () => {
        Polling.stop();

        expect(service.fetch.calls.count()).toEqual(2);
        expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
        expect(Polling.stop).toHaveBeenCalled();
        expect(Polling.restart).toHaveBeenCalled();

        Vue.http.interceptors = _.without(Vue.http.interceptors, pollInterceptor);

        done();
      });
    });
  });
});
