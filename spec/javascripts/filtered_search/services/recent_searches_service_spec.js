import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import AccessorUtilities from '~/lib/utils/accessor';

describe('RecentSearchesService', () => {
  let service;

  beforeEach(() => {
    service = new RecentSearchesService();
    window.localStorage.removeItem(service.localStorageKey);
  });

  describe('fetch', () => {
    beforeEach(() => {
      spyOn(RecentSearchesService, 'isAvailable').and.returnValue(true);
    });

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
        .catch((error) => {
          expect(error).toEqual(jasmine.any(SyntaxError));
          done();
        });
    });

    it('should reject when service is unavailable', (done) => {
      RecentSearchesService.isAvailable.and.returnValue(false);

      service.fetch().catch((error) => {
        expect(error).toEqual(jasmine.any(Error));
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

    describe('if .isAvailable returns `false`', () => {
      beforeEach(() => {
        RecentSearchesService.isAvailable.and.returnValue(false);

        spyOn(window.localStorage, 'getItem');

        RecentSearchesService.prototype.fetch();
      });

      it('should not call .getItem', () => {
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });
  });

  describe('setRecentSearches', () => {
    beforeEach(() => {
      spyOn(RecentSearchesService, 'isAvailable').and.returnValue(true);
    });

    it('should save things in localStorage', () => {
      const items = ['foo', 'bar'];
      service.save(items);
      const newLocalStorageValue = window.localStorage.getItem(service.localStorageKey);
      expect(JSON.parse(newLocalStorageValue)).toEqual(items);
    });
  });

  describe('save', () => {
    beforeEach(() => {
      spyOn(window.localStorage, 'setItem');
      spyOn(RecentSearchesService, 'isAvailable');
    });

    describe('if .isAvailable returns `true`', () => {
      const searchesString = 'searchesString';
      const localStorageKey = 'localStorageKey';
      const recentSearchesService = {
        localStorageKey,
      };

      beforeEach(() => {
        RecentSearchesService.isAvailable.and.returnValue(true);

        spyOn(JSON, 'stringify').and.returnValue(searchesString);

        RecentSearchesService.prototype.save.call(recentSearchesService);
      });

      it('should call .setItem', () => {
        expect(window.localStorage.setItem).toHaveBeenCalledWith(localStorageKey, searchesString);
      });
    });

    describe('if .isAvailable returns `false`', () => {
      beforeEach(() => {
        RecentSearchesService.isAvailable.and.returnValue(false);

        RecentSearchesService.prototype.save();
      });

      it('should not call .setItem', () => {
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });
  });

  describe('isAvailable', () => {
    let isAvailable;

    beforeEach(() => {
      spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').and.callThrough();

      isAvailable = RecentSearchesService.isAvailable();
    });

    it('should call .isLocalStorageAccessSafe', () => {
      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
    });

    it('should return a boolean', () => {
      expect(typeof isAvailable).toBe('boolean');
    });
  });
});
