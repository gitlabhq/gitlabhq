import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

describe('PerformanceBarService', () => {
  describe('callbackParams', () => {
    describe('fireCallback', () => {
      function fireCallback(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[0];
      }

      it('returns false when the request URL is the peek URL', () => {
        expect(fireCallback({ headers: { 'x-request-id': '123' }, url: '/peek' }, '/peek'))
          .toBeFalsy();
      });

      it('returns false when there is no request ID', () => {
        expect(fireCallback({ headers: {}, url: '/request' }, '/peek'))
          .toBeFalsy();
      });

      it('returns false when the request is an API request', () => {
        expect(fireCallback({ headers: { 'x-request-id': '123' }, url: '/api/' }, '/peek'))
          .toBeFalsy();
      });

      it('returns false when the response is from the cache', () => {
        expect(fireCallback({ headers: { 'x-request-id': '123', 'x-gitlab-from-cache': 'true' }, url: '/request' }, '/peek'))
          .toBeFalsy();
      });

      it('returns true when all conditions are met', () => {
        expect(fireCallback({ headers: { 'x-request-id': '123' }, url: '/request' }, '/peek'))
          .toBeTruthy();
      });
    });

    describe('requestId', () => {
      function requestId(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[1];
      }

      it('gets the request ID from the headers', () => {
        expect(requestId({ headers: { 'x-request-id': '123' } }, '/peek'))
          .toEqual('123');
      });
    });

    describe('requestUrl', () => {
      function requestUrl(response, peekUrl) {
        return PerformanceBarService.callbackParams(response, peekUrl)[2];
      }

      it('gets the request URL from the response object', () => {
        expect(requestUrl({ headers: {}, url: '/request' }, '/peek'))
          .toEqual('/request');
      });

      it('gets the request URL from response.config if present', () => {
        expect(requestUrl({ headers: {}, config: { url: '/config-url' }, url: '/request' }, '/peek'))
          .toEqual('/config-url');
      });
    });
  });
});
