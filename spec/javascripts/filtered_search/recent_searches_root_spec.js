import RecentSearchesRoot from '~/filtered_search/recent_searches_root';
import * as vueSrc from 'vue';

describe('RecentSearchesRoot', () => {
  describe('render', () => {
    let recentSearchesRoot;
    let data;
    let template;

    beforeEach(() => {
      recentSearchesRoot = {
        store: {
          state: 'state',
        },
      };

      spyOn(vueSrc, 'default').and.callFake((options) => {
        data = options.data;
        template = options.template;
      });

      RecentSearchesRoot.prototype.render.call(recentSearchesRoot);
    });

    it('should instantiate Vue', () => {
      expect(vueSrc.default).toHaveBeenCalled();
      expect(data()).toBe(recentSearchesRoot.store.state);
      expect(template).toContain(':is-local-storage-available="isLocalStorageAvailable"');
    });
  });
});
