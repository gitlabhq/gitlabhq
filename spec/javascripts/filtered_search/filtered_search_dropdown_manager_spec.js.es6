//= require filtered_search/filtered_search_tokenizer
//= require filtered_search/filtered_search_dropdown_manager

(() => {
  describe('Filtered Search Dropdown Manager', () => {
    describe('addWordToInput', () => {
      function getInputValue() {
        return document.querySelector('.filtered-search').value;
      }

      beforeEach(() => {
        const input = document.createElement('input');
        input.classList.add('filtered-search');
        document.body.appendChild(input);

        expect(input.value).toBe('');
      });

      afterEach(() => {
        document.querySelector('.filtered-search').outerHTML = '';
      });

      describe('input has no existing value', () => {
        beforeEach(() => {
          spyOn(gl.FilteredSearchTokenizer, 'processTokens')
            .and.callFake(() => ({
              lastToken: {},
            }));
        });

        it('should add word', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInputValue()).toBe('firstWord');
        });

        it('should not add space before first word', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord', true);
          expect(getInputValue()).toBe('firstWord');
        });

        it('should not add space before second word by default', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInputValue()).toBe('firstWord');
          gl.FilteredSearchDropdownManager.addWordToInput('secondWord');
          expect(getInputValue()).toBe('firstWordsecondWord');
        });

        it('should add space before new word when addSpace is passed', () => {
          expect(getInputValue()).toBe('');
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInputValue()).toBe('firstWord');
          gl.FilteredSearchDropdownManager.addWordToInput('secondWord', true);
          expect(getInputValue()).toBe('firstWord secondWord');
        });
      });

      describe('input has exsting value', () => {
        it('should only add the remaining characters of the word', () => {
          const lastToken = {
            key: 'author',
            value: 'roo',
          };

          spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.callFake(() => ({
            lastToken,
          }));

          document.querySelector('.filtered-search').value = `${lastToken.key}:${lastToken.value}`;
          gl.FilteredSearchDropdownManager.addWordToInput('root');
          expect(getInputValue()).toBe('author:root');
        });

        it('should only add the remaining characters of the word (contains space)', () => {
          const lastToken = {
            key: 'label',
            value: 'test me',
          };

          spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.callFake(() => ({
            lastToken,
          }));

          document.querySelector('.filtered-search').value = `${lastToken.key}:"${lastToken.value}"`;
          gl.FilteredSearchDropdownManager.addWordToInput('~\'"test me"\'');
          expect(getInputValue()).toBe('label:~\'"test me"\'');
        });
      });
    });
  });
})();
