require('~/extensions/array');
require('~/filtered_search/filtered_search_tokenizer');
require('~/filtered_search/filtered_search_dropdown_manager');

(() => {
  describe('Filtered Search Dropdown Manager', () => {
    describe('addWordToInput', () => {
      function getInputValue() {
        return document.querySelector('.filtered-search').value;
      }

      function setInputValue(value) {
        document.querySelector('.filtered-search').value = value;
      }

      beforeEach(() => {
        const input = document.createElement('input');
        input.classList.add('filtered-search');
        document.body.appendChild(input);
      });

      afterEach(() => {
        document.querySelector('.filtered-search').outerHTML = '';
      });

      describe('input has no existing value', () => {
        it('should add just tokenName', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('milestone');
          expect(getInputValue()).toBe('milestone:');
        });

        it('should add tokenName and tokenValue', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('label', 'none');
          expect(getInputValue()).toBe('label:none ');
        });
      });

      describe('input has existing value', () => {
        it('should be able to just add tokenName', () => {
          setInputValue('a');
          gl.FilteredSearchDropdownManager.addWordToInput('author');
          expect(getInputValue()).toBe('author:');
        });

        it('should replace tokenValue', () => {
          setInputValue('author:roo');
          gl.FilteredSearchDropdownManager.addWordToInput('author', '@root');
          expect(getInputValue()).toBe('author:@root ');
        });

        it('should add tokenValues containing spaces', () => {
          setInputValue('label:~"test');
          gl.FilteredSearchDropdownManager.addWordToInput('label', '~\'"test me"\'');
          expect(getInputValue()).toBe('label:~\'"test me"\' ');
        });
      });
    });
  });
})();
