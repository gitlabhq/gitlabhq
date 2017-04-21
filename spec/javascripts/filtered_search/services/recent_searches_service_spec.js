/* eslint-disable promise/catch-or-return */

import RecentSearchesService from '~/filtered_search/services/recent_searches_service';

describe('RecentSearchesService', () => {
  let service;

  beforeEach(() => {
    service = new RecentSearchesService();
    window.localStorage.removeItem(service.localStorageKey);
  });

  describe('fetch', () => {
    it('should default to empty array', (done) => {
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .then((items) => {
          expect(items).toEqual([]);
          done();
        })
        .catch((err) => {
          done.fail('Shouldn\'t reject with empty localStorage key', err);
        });
    });

    it('should reject when unable to parse', (done) => {
      window.localStorage.setItem(service.localStorageKey, 'fail');
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .catch(() => {
          done();
        });
    });

    it('should return items from localStorage', (done) => {
      window.localStorage.setItem(service.localStorageKey, '["foo", "bar"]');
      const fetchItemsPromise = service.fetch();

      fetchItemsPromise
        .then((items) => {
          expect(items).toEqual(['foo', 'bar']);
          done();
        });
    });
  });

  describe('setRecentSearches', () => {
    it('should save things in localStorage', () => {
      const items = ['foo', 'bar'];
      service.save(items);
      const newLocalStorageValue =
        window.localStorage.getItem(service.localStorageKey);
      expect(JSON.parse(newLocalStorageValue)).toEqual(items);
    });
  });
});
