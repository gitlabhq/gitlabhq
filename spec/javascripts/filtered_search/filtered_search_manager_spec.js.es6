require('~/lib/utils/url_utility');
require('~/lib/utils/common_utils');
require('~/filtered_search/filtered_search_token_keys');
require('~/filtered_search/filtered_search_tokenizer');
require('~/filtered_search/filtered_search_dropdown_manager');
require('~/filtered_search/filtered_search_manager');

(() => {
  describe('Filtered Search Manager', () => {
    describe('search', () => {
      let manager;
      const defaultParams = '?scope=all&utf8=✓&state=opened';

      function getInput() {
        return document.querySelector('.filtered-search');
      }

      beforeEach(() => {
        setFixtures(`
          <input type='text' class='filtered-search' />
        `);

        spyOn(gl.FilteredSearchManager.prototype, 'bindEvents').and.callFake(() => {});
        spyOn(gl.FilteredSearchManager.prototype, 'cleanup').and.callFake(() => {});
        spyOn(gl.FilteredSearchManager.prototype, 'loadSearchParamsFromURL').and.callFake(() => {});
        spyOn(gl.FilteredSearchDropdownManager.prototype, 'setDropdown').and.callFake(() => {});
        spyOn(gl.utils, 'getParameterByName').and.returnValue(null);

        manager = new gl.FilteredSearchManager();
      });

      afterEach(() => {
        getInput().outerHTML = '';
      });

      it('should search with a single word', () => {
        getInput().value = 'searchTerm';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=searchTerm`);
        });

        manager.search();
      });

      it('should search with multiple words', () => {
        getInput().value = 'awesome search terms';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=awesome+search+terms`);
        });

        manager.search();
      });

      it('should search with special characters', () => {
        getInput().value = '~!@#$%^&*()_+{}:<>,.?/';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=~!%40%23%24%25%5E%26*()_%2B%7B%7D%3A%3C%3E%2C.%3F%2F`);
        });

        manager.search();
      });
    });
  });
})();
