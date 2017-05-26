import * as recentSearchesStoreSrc from '~/filtered_search/stores/recent_searches_store';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesServiceError from '~/filtered_search/services/recent_searches_service_error';

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

    function dispatchBackspaceEvent(element, eventType) {
      const backspaceKey = 8;
      const event = new Event(eventType);
      event.keyCode = backspaceKey;
      element.dispatchEvent(event);
    }

    function dispatchDeleteEvent(element, eventType) {
      const deleteKey = 46;
      const event = new Event(eventType);
      event.keyCode = deleteKey;
      element.dispatchEvent(event);
    }

    beforeEach(() => {
      setFixtures(`
        <div class="filtered-search-box">
          <form>
            <ul class="tokens-container list-unstyled">
              ${FilteredSearchSpecHelper.createInputHTML(placeholder)}
            </ul>
            <button class="clear-search" type="button">
              <i class="fa fa-times"></i>
            </button>
          </form>
        </div>
      `);

      spyOn(gl.FilteredSearchManager.prototype, 'loadSearchParamsFromURL').and.callFake(() => {});
      spyOn(gl.FilteredSearchManager.prototype, 'tokenChange').and.callFake(() => {});
      spyOn(gl.FilteredSearchDropdownManager.prototype, 'setDropdown').and.callFake(() => {});
      spyOn(gl.FilteredSearchDropdownManager.prototype, 'updateDropdownOffset').and.callFake(() => {});
      spyOn(gl.utils, 'getParameterByName').and.returnValue(null);
      spyOn(gl.FilteredSearchVisualTokens, 'unselectTokens').and.callThrough();

      input = document.querySelector('.filtered-search');
      tokensContainer = document.querySelector('.tokens-container');
      manager = new gl.FilteredSearchManager();
    });

    afterEach(() => {
      manager.cleanup();
    });

    describe('class constructor', () => {
      const isLocalStorageAvailable = 'isLocalStorageAvailable';
      let filteredSearchManager;

      beforeEach(() => {
        spyOn(RecentSearchesService, 'isAvailable').and.returnValue(isLocalStorageAvailable);
        spyOn(recentSearchesStoreSrc, 'default');

        filteredSearchManager = new gl.FilteredSearchManager();

        return filteredSearchManager;
      });

      it('should instantiate RecentSearchesStore with isLocalStorageAvailable', () => {
        expect(RecentSearchesService.isAvailable).toHaveBeenCalled();
        expect(recentSearchesStoreSrc.default).toHaveBeenCalledWith({
          isLocalStorageAvailable,
        });
      });

      it('should not instantiate Flash if an RecentSearchesServiceError is caught', () => {
        spyOn(RecentSearchesService.prototype, 'fetch').and.callFake(() => Promise.reject(new RecentSearchesServiceError()));
        spyOn(window, 'Flash');

        filteredSearchManager = new gl.FilteredSearchManager();

        expect(window.Flash).not.toHaveBeenCalled();
      });
    });

    describe('search', () => {
      const defaultParams = '?scope=all&utf8=%E2%9C%93&state=opened';

      it('should search with a single word', (done) => {
        input.value = 'searchTerm';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=searchTerm`);
          done();
        });

        manager.search();
      });

      it('should search with multiple words', (done) => {
        input.value = 'awesome search terms';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=awesome+search+terms`);
          done();
        });

        manager.search();
      });

      it('should search with special characters', (done) => {
        input.value = '~!@#$%^&*()_+{}:<>,.?/';

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&search=~!%40%23%24%25%5E%26*()_%2B%7B%7D%3A%3C%3E%2C.%3F%2F`);
          done();
        });

        manager.search();
      });

      it('removes duplicated tokens', (done) => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
        `);

        spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
          expect(url).toEqual(`${defaultParams}&label_name[]=bug`);
          done();
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
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug'),
        );

        const event = new Event('input');
        input.dispatchEvent(event);

        expect(input.placeholder).toEqual('');
      });
    });

    describe('checkForBackspace', () => {
      describe('tokens and no input', () => {
        beforeEach(() => {
          tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
            FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug'),
          );
        });

        it('removes last token', () => {
          spyOn(gl.FilteredSearchVisualTokens, 'removeLastTokenPartial').and.callThrough();
          dispatchBackspaceEvent(input, 'keyup');

          expect(gl.FilteredSearchVisualTokens.removeLastTokenPartial).toHaveBeenCalled();
        });

        it('sets the input', () => {
          spyOn(gl.FilteredSearchVisualTokens, 'getLastTokenPartial').and.callThrough();
          dispatchDeleteEvent(input, 'keyup');

          expect(gl.FilteredSearchVisualTokens.getLastTokenPartial).toHaveBeenCalled();
          expect(input.value).toEqual('~bug');
        });
      });

      it('does not remove token or change input when there is existing input', () => {
        spyOn(gl.FilteredSearchVisualTokens, 'removeLastTokenPartial').and.callThrough();
        spyOn(gl.FilteredSearchVisualTokens, 'getLastTokenPartial').and.callThrough();

        input.value = 'text';
        dispatchDeleteEvent(input, 'keyup');

        expect(gl.FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
        expect(gl.FilteredSearchVisualTokens.getLastTokenPartial).not.toHaveBeenCalled();
        expect(input.value).toEqual('text');
      });
    });

    describe('removeSelectedToken', () => {
      function getVisualTokens() {
        return tokensContainer.querySelectorAll('.js-visual-token');
      }

      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'none', true),
        );
      });

      it('removes selected token when the backspace key is pressed', () => {
        expect(getVisualTokens().length).toEqual(1);

        dispatchBackspaceEvent(document, 'keydown');

        expect(getVisualTokens().length).toEqual(0);
      });

      it('removes selected token when the delete key is pressed', () => {
        expect(getVisualTokens().length).toEqual(1);

        dispatchDeleteEvent(document, 'keydown');

        expect(getVisualTokens().length).toEqual(0);
      });

      it('updates the input placeholder after removal', () => {
        manager.handleInputPlaceholder();

        expect(input.placeholder).toEqual('');
        expect(getVisualTokens().length).toEqual(1);

        dispatchBackspaceEvent(document, 'keydown');

        expect(input.placeholder).not.toEqual('');
        expect(getVisualTokens().length).toEqual(0);
      });

      it('updates the clear button after removal', () => {
        manager.toggleClearSearchButton();

        const clearButton = document.querySelector('.clear-search');

        expect(clearButton.classList.contains('hidden')).toEqual(false);
        expect(getVisualTokens().length).toEqual(1);

        dispatchBackspaceEvent(document, 'keydown');

        expect(clearButton.classList.contains('hidden')).toEqual(true);
        expect(getVisualTokens().length).toEqual(0);
      });
    });

    describe('unselects token', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug', true)}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~awesome')}
        `);
      });

      it('unselects token when input is clicked', () => {
        const selectedToken = tokensContainer.querySelector('.js-visual-token .selected');

        expect(selectedToken.classList.contains('selected')).toEqual(true);
        expect(gl.FilteredSearchVisualTokens.unselectTokens).not.toHaveBeenCalled();

        // Click directly on input attached to document
        // so that the click event will propagate properly
        document.querySelector('.filtered-search').click();

        expect(gl.FilteredSearchVisualTokens.unselectTokens).toHaveBeenCalled();
        expect(selectedToken.classList.contains('selected')).toEqual(false);
      });

      it('unselects token when document.body is clicked', () => {
        const selectedToken = tokensContainer.querySelector('.js-visual-token .selected');

        expect(selectedToken.classList.contains('selected')).toEqual(true);
        expect(gl.FilteredSearchVisualTokens.unselectTokens).not.toHaveBeenCalled();

        document.body.click();

        expect(selectedToken.classList.contains('selected')).toEqual(false);
        expect(gl.FilteredSearchVisualTokens.unselectTokens).toHaveBeenCalled();
      });
    });

    describe('toggleInputContainerFocus', () => {
      it('toggles on focus', () => {
        input.focus();
        expect(document.querySelector('.filtered-search-box').classList.contains('focus')).toEqual(true);
      });

      it('toggles on blur', () => {
        input.blur();
        expect(document.querySelector('.filtered-search-box').classList.contains('focus')).toEqual(false);
      });
    });
  });
})();
