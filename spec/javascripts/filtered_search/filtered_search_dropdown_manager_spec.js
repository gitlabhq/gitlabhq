import $ from 'jquery';
import FilteredSearchDropdownManager from '~/filtered_search/filtered_search_dropdown_manager';

describe('Filtered Search Dropdown Manager', () => {
  beforeEach(() => {
    spyOn($, 'ajax');
  });

  describe('addWordToInput', () => {
    function getInputValue() {
      return document.querySelector('.filtered-search').value;
    }

    function setInputValue(value) {
      document.querySelector('.filtered-search').value = value;
    }

    beforeEach(() => {
      setFixtures(`
        <ul class="tokens-container">
          <li class="input-token">
            <input class="filtered-search">
          </li>
        </ul>
      `);
    });

    describe('input has no existing value', () => {
      it('should add just tokenName', () => {
        FilteredSearchDropdownManager.addWordToInput('milestone');

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('milestone');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenName and tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput('label');

        let token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(getInputValue()).toBe('');

        FilteredSearchDropdownManager.addWordToInput('label', 'none');
        // We have to get that reference again
        // Because FilteredSearchDropdownManager deletes the previous token
        token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(token.querySelector('.value').innerText).toBe('none');
        expect(getInputValue()).toBe('');
      });
    });

    describe('input has existing value', () => {
      it('should be able to just add tokenName', () => {
        setInputValue('a');
        FilteredSearchDropdownManager.addWordToInput('author');

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('author');
        expect(getInputValue()).toBe('');
      });

      it('should replace tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput('author');

        setInputValue('roo');
        FilteredSearchDropdownManager.addWordToInput(null, '@root');

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('author');
        expect(token.querySelector('.value').innerText).toBe('@root');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenValues containing spaces', () => {
        FilteredSearchDropdownManager.addWordToInput('label');

        setInputValue('"test ');
        FilteredSearchDropdownManager.addWordToInput('label', '~\'"test me"\'');

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(token.querySelector('.value').innerText).toBe('~\'"test me"\'');
        expect(getInputValue()).toBe('');
      });
    });
  });
});
