require('~/lib/utils/url_utility');
require('~/lib/utils/common_utils');
require('~/filtered_search/filtered_search_token_keys');
require('~/filtered_search/filtered_search_tokenizer');
require('~/filtered_search/filtered_search_dropdown_manager');
require('~/filtered_search/filtered_search_manager');

(() => {
  describe('Filtered Search Manager', () => {
    let input;

    describe('search', () => {
      let manager;
      const defaultParams = '?scope=all&utf8=✓&state=opened';

      beforeEach(() => {
        setFixtures(`
          <input type='text' class='filtered-search' />
        `);

        spyOn(gl.FilteredSearchManager.prototype, 'bindEvents').and.callFake(() => {});
        spyOn(gl.FilteredSearchManager.prototype, 'cleanup').and.callFake(() => {});
        spyOn(gl.FilteredSearchManager.prototype, 'loadSearchParamsFromURL').and.callFake(() => {});
        spyOn(gl.FilteredSearchDropdownManager.prototype, 'setDropdown').and.callFake(() => {});
        spyOn(gl.utils, 'getParameterByName').and.returnValue(null);

        input = document.querySelector('.filtered-search');
        manager = new gl.FilteredSearchManager();
      });

      afterEach(() => {
        input.outerHTML = '';
      });

      it('should search with a single word', () => {
        input.value = 'searchTerm';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=searchTerm`);
        });

        manager.search();
      });

      it('should search with multiple words', () => {
        input.value = 'awesome search terms';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=awesome+search+terms`);
        });

        manager.search();
      });

      it('should search with special characters', () => {
        input.value = '~!@#$%^&*()_+{}:<>,.?/';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=~!%40%23%24%25%5E%26*()_%2B%7B%7D%3A%3C%3E%2C.%3F%2F`);
        });

        manager.search();
      });
    });

    describe('handleInputPlaceholder', () => {
      const placeholder = 'Search or filter results...';
      let tokensContainer;

      beforeEach(() => {
        setFixtures(`
          <form>
            <ul class="tokens-container list-unstyled"></ul>
            <input type='text' class='filtered-search' placeholder='${placeholder}' />
            <button class="clear-search" type="button">
              <i class="fa fa-times"></i>
            </button>
          </form>
        `);

        spyOn(gl.FilteredSearchManager.prototype, 'cleanup').and.callFake(() => {});
        spyOn(gl.FilteredSearchManager.prototype, 'loadSearchParamsFromURL').and.callFake(() => {});
        spyOn(gl.FilteredSearchDropdownManager.prototype, 'setDropdown').and.callFake(() => {});
        spyOn(gl.utils, 'getParameterByName').and.returnValue(null);

        input = document.querySelector('.filtered-search');
        tokensContainer = document.querySelector('.tokens-container');
        return new gl.FilteredSearchManager();
      });

      afterEach(() => {
        input.outerHTML = '';
        tokensContainer.innerHTML = '';
      });

      it('should render placeholder when there is no input', () => {
        expect(input.placeholder).toEqual(placeholder);
      });

      it('should not render placeholder when there is input', () => {
        input.value = 'test words';

        const event = new Event('input');
        input.dispatchEvent(event);

        expect(input.placeholder).toEqual('');
      });

      it('should not render placeholder when there are tokens and no input', () => {
        tokensContainer.innerHTML = `
          <li class="js-visual-token filtered-search-token">
            <div class="name">label</div>
            <div class="value">~bug</div>
          </li>
        `;

        const event = new Event('input');
        input.dispatchEvent(event);

        expect(input.placeholder).toEqual('');
      });
    });
  });
})();
