require('~/lib/utils/url_utility');
require('~/lib/utils/common_utils');
require('~/filtered_search/filtered_search_token_keys');
require('~/filtered_search/filtered_search_tokenizer');
require('~/filtered_search/filtered_search_dropdown_manager');
require('~/filtered_search/filtered_search_manager');
const FilteredSearchSpecHelper = require('../helpers/filtered_search_spec_helper');

(() => {
  describe('Filtered Search Manager', () => {
    let input;
    let manager;
    let tokensContainer;
    const placeholder = 'Search or filter results...';

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
      spyOn(gl.FilteredSearchManager.prototype, 'tokenChange').and.callFake(() => {});
      spyOn(gl.FilteredSearchDropdownManager.prototype, 'setDropdown').and.callFake(() => {});
      spyOn(gl.FilteredSearchDropdownManager.prototype, 'updateDropdownOffset').and.callFake(() => {});
      spyOn(gl.utils, 'getParameterByName').and.returnValue(null);

      input = document.querySelector('.filtered-search');
      tokensContainer = document.querySelector('.tokens-container');
      manager = new gl.FilteredSearchManager();
    });

    afterEach(() => {
      tokensContainer.innerHTML = '';
    });

    describe('search', () => {
      const defaultParams = '?scope=all&utf8=✓&state=opened';

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
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug');

        const event = new Event('input');
        input.dispatchEvent(event);

        expect(input.placeholder).toEqual('');
      });
    });

    describe('checkForBackspace', () => {
      const backspaceKey = 8;
      const deleteKey = 46;

      describe('tokens and no input', () => {
        beforeEach(() => {
          tokensContainer.innerHTML = FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug');
        });

        it('removes last token', () => {
          spyOn(gl.FilteredSearchVisualTokens, 'removeLastTokenPartial').and.callThrough();

          const event = new Event('keyup');
          event.keyCode = backspaceKey;
          input.dispatchEvent(event);

          expect(gl.FilteredSearchVisualTokens.removeLastTokenPartial).toHaveBeenCalled();
        });

        it('sets the input', () => {
          spyOn(gl.FilteredSearchVisualTokens, 'getLastTokenPartial').and.callThrough();

          const event = new Event('keyup');
          event.keyCode = deleteKey;
          input.dispatchEvent(event);

          expect(gl.FilteredSearchVisualTokens.getLastTokenPartial).toHaveBeenCalled();
          expect(input.value).toEqual('~bug');
        });
      });

      it('does not remove token or change input when there is existing input', () => {
        spyOn(gl.FilteredSearchVisualTokens, 'removeLastTokenPartial').and.callThrough();
        spyOn(gl.FilteredSearchVisualTokens, 'getLastTokenPartial').and.callThrough();

        input.value = 'text';

        const event = new Event('keyup');
        event.keyCode = deleteKey;
        input.dispatchEvent(event);

        expect(gl.FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
        expect(gl.FilteredSearchVisualTokens.getLastTokenPartial).not.toHaveBeenCalled();
        expect(input.value).toEqual('text');
      });
    });

    describe('unselects token', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = `
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug', true)}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~awesome')}
        `;
      });

      it('unselects token when input is clicked', () => {
        const selectedToken = tokensContainer.querySelector('.js-visual-token .selected');

        expect(selectedToken.classList.contains('selected')).toEqual(true);

        input.click();

        expect(selectedToken.classList.contains('selected')).toEqual(false);
      });

      it('unselects token when document.body is clicked', () => {
        const selectedToken = tokensContainer.querySelector('.js-visual-token .selected');

        expect(selectedToken.classList.contains('selected')).toEqual(true);

        document.body.click();

        expect(selectedToken.classList.contains('selected')).toEqual(false);
      });
    });
  });
})();
