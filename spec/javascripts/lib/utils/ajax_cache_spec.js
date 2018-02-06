import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AjaxCache from '~/lib/utils/ajax_cache';

describe('AjaxCache', () => {
  const dummyEndpoint = '/AjaxCache/dummyEndpoint';
  const dummyResponse = {
    important: 'dummy data',
  };

  beforeEach(() => {
    AjaxCache.internalStorage = { };
    AjaxCache.pendingRequests = { };
  });

  describe('get', () => {
    it('returns undefined if cache is empty', () => {
      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(undefined);
    });

    it('returns undefined if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(undefined);
    });

    it('returns matching data', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(dummyResponse);
    });
  });

  describe('hasData', () => {
    it('returns false if cache is empty', () => {
      expect(AjaxCache.hasData(dummyEndpoint)).toBe(false);
    });

    it('returns false if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      expect(AjaxCache.hasData(dummyEndpoint)).toBe(false);
    });

    it('returns true if data is available', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      expect(AjaxCache.hasData(dummyEndpoint)).toBe(true);
    });
  });

  describe('remove', () => {
    it('does nothing if cache is empty', () => {
      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({ });
    });

    it('does nothing if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage['not matching']).toBe(dummyResponse);
    });

    it('removes matching data', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({ });
    });
  });

  describe('override', () => {
    it('overrides existing cache', () => {
      AjaxCache.internalStorage.endpoint = 'existing-endpoint';
      AjaxCache.override('endpoint', 'new-endpoint');

      expect(AjaxCache.internalStorage.endpoint).toEqual('new-endpoint');
    });
  });

  describe('retrieve', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);

      spyOn(axios, 'get').and.callThrough();
    });

    afterEach(() => {
      mock.restore();
    });

    it('stores and returns data from Ajax call if cache is empty', (done) => {
      mock.onGet(dummyEndpoint).reply(200, dummyResponse);

      AjaxCache.retrieve(dummyEndpoint)
      .then((data) => {
        expect(data).toEqual(dummyResponse);
        expect(AjaxCache.internalStorage[dummyEndpoint]).toEqual(dummyResponse);
      })
      .then(done)
      .catch(fail);
    });

    it('makes no Ajax call if request is pending', (done) => {
      mock.onGet(dummyEndpoint).reply(200, dummyResponse);

      AjaxCache.retrieve(dummyEndpoint)
      .then(done)
      .catch(fail);

      AjaxCache.retrieve(dummyEndpoint)
      .then(done)
      .catch(fail);

      expect(axios.get.calls.count()).toBe(1);
    });

    it('returns undefined if Ajax call fails and cache is empty', (done) => {
      const errorMessage = 'Network Error';
      mock.onGet(dummyEndpoint).networkError();

      AjaxCache.retrieve(dummyEndpoint)
      .then(data => fail(`Received unexpected data: ${JSON.stringify(data)}`))
      .catch((error) => {
        expect(error.message).toBe(`${dummyEndpoint}: ${errorMessage}`);
        expect(error.textStatus).toBe(errorMessage);
        done();
      })
      .catch(fail);
    });

    it('makes no Ajax call if matching data exists', (done) => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;
      mock.onGet(dummyEndpoint).reply(() => {
        fail(new Error('expected no Ajax call!'));
      });

      AjaxCache.retrieve(dummyEndpoint)
      .then((data) => {
        expect(data).toBe(dummyResponse);
      })
      .then(done)
      .catch(fail);
    });

    it('makes Ajax call even if matching data exists when forceRequest parameter is provided', (done) => {
      const oldDummyResponse = {
        important: 'old dummy data',
      };

      AjaxCache.internalStorage[dummyEndpoint] = oldDummyResponse;

      mock.onGet(dummyEndpoint).reply(200, dummyResponse);

      // Call without forceRetrieve param
      AjaxCache.retrieve(dummyEndpoint)
        .then((data) => {
          expect(data).toBe(oldDummyResponse);
        })
        .then(done)
        .catch(fail);

      // Call with forceRetrieve param
      AjaxCache.retrieve(dummyEndpoint, true)
        .then((data) => {
          expect(data).toEqual(dummyResponse);
        })
        .then(done)
        .catch(fail);
    });
  });
});
