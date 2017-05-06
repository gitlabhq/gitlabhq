import AjaxCache from '~/lib/utils/ajax_cache';

describe('AjaxCache', () => {
  const dummyEndpoint = '/AjaxCache/dummyEndpoint';
  const dummyResponse = {
    important: 'dummy data',
  };
  let ajaxSpy = (url) => {
    expect(url).toBe(dummyEndpoint);
    const deferred = $.Deferred();
    deferred.resolve(dummyResponse);
    return deferred.promise();
  };

  beforeEach(() => {
    AjaxCache.internalStorage = { };
    spyOn(jQuery, 'ajax').and.callFake(url => ajaxSpy(url));
  });

  describe('#get', () => {
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

  describe('#hasData', () => {
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

  describe('#purge', () => {
    it('does nothing if cache is empty', () => {
      AjaxCache.purge(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({ });
    });

    it('does nothing if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      AjaxCache.purge(dummyEndpoint);

      expect(AjaxCache.internalStorage['not matching']).toBe(dummyResponse);
    });

    it('removes matching data', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      AjaxCache.purge(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({ });
    });
  });

  describe('#retrieve', () => {
    it('stores and returns data from Ajax call if cache is empty', (done) => {
      AjaxCache.retrieve(dummyEndpoint)
      .then((data) => {
        expect(data).toBe(dummyResponse);
        expect(AjaxCache.internalStorage[dummyEndpoint]).toBe(dummyResponse);
      })
      .then(done)
      .catch(fail);
    });

    it('returns undefined if Ajax call fails and cache is empty', (done) => {
      const dummyStatusText = 'exploded';
      const dummyErrorMessage = 'server exploded';
      ajaxSpy = (url) => {
        expect(url).toBe(dummyEndpoint);
        const deferred = $.Deferred();
        deferred.reject(null, dummyStatusText, dummyErrorMessage);
        return deferred.promise();
      };

      AjaxCache.retrieve(dummyEndpoint)
      .then(data => fail(`Received unexpected data: ${JSON.stringify(data)}`))
      .catch((error) => {
        expect(error.message).toBe(`${dummyEndpoint}: ${dummyErrorMessage}`);
        expect(error.textStatus).toBe(dummyStatusText);
        done();
      })
      .catch(fail);
    });

    it('makes no Ajax call if matching data exists', (done) => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;
      ajaxSpy = () => fail(new Error('expected no Ajax call!'));

      AjaxCache.retrieve(dummyEndpoint)
      .then((data) => {
        expect(data).toBe(dummyResponse);
      })
      .then(done)
      .catch(fail);
    });
  });
});
