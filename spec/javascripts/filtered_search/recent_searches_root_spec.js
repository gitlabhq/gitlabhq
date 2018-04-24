import RecentSearchesRoot from '~/filtered_search/recent_searches_root';

describe('RecentSearchesRoot', () => {
  describe('render', () => {
    let recentSearchesRoot;
    let data;
    let template;
    let VueSpy;

    beforeEach(() => {
      recentSearchesRoot = {
        store: {
          state: 'state',
        },
      };

      VueSpy = spyOnDependency(RecentSearchesRoot, 'Vue').and.callFake((options) => {
        data = options.data;
        template = options.template;
      });

      RecentSearchesRoot.prototype.render.call(recentSearchesRoot);
    });

    it('should instantiate Vue', () => {
      expect(VueSpy).toHaveBeenCalled();
      expect(data()).toBe(recentSearchesRoot.store.state);
      expect(template).toContain(':is-local-storage-available="isLocalStorageAvailable"');
    });
  });
});
