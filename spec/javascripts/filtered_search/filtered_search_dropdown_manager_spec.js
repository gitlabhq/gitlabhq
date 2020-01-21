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
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'milestone' });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('milestone');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenName, tokenOperator, and tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label' });

        let token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(getInputValue()).toBe('');

        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label', tokenOperator: '=' });

        token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(token.querySelector('.operator').innerText).toBe('=');
        expect(getInputValue()).toBe('');

        FilteredSearchDropdownManager.addWordToInput({
          tokenName: 'label',
          tokenOperator: '=',
          tokenValue: 'none',
        });
        // We have to get that reference again
        // Because FilteredSearchDropdownManager deletes the previous token
        token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(token.querySelector('.operator').innerText).toBe('=');
        expect(token.querySelector('.value').innerText).toBe('none');
        expect(getInputValue()).toBe('');
      });
    });

    describe('input has existing value', () => {
      it('should be able to just add tokenName', () => {
        setInputValue('a');
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author' });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('author');
        expect(getInputValue()).toBe('');
      });

      it('should replace tokenValue', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author' });
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'author', tokenOperator: '=' });

        setInputValue('roo');
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: null,
          tokenOperator: '=',
          tokenValue: '@root',
        });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('author');
        expect(token.querySelector('.operator').innerText).toBe('=');
        expect(token.querySelector('.value').innerText).toBe('@root');
        expect(getInputValue()).toBe('');
      });

      it('should add tokenValues containing spaces', () => {
        FilteredSearchDropdownManager.addWordToInput({ tokenName: 'label' });

        setInputValue('"test ');
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: 'label',
          tokenOperator: '=',
          tokenValue: '~\'"test me"\'',
        });

        const token = document.querySelector('.tokens-container .js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toBe('label');
        expect(token.querySelector('.operator').innerText).toBe('=');
        expect(token.querySelector('.value').innerText).toBe('~\'"test me"\'');
        expect(getInputValue()).toBe('');
      });
    });
  });
});
