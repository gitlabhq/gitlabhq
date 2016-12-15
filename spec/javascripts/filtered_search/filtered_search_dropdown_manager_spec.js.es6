//= require filtered_search/filtered_search_tokenizer
//= require filtered_search/filtered_search_dropdown_manager

(() => {
  describe('Filtered Search Dropdown Manager', () => {
    describe('addWordToInput', () => {
      describe('add word and when lastToken is an empty object', () => {
        function getInput() {
          return document.querySelector('.filtered-search');
        }

        beforeEach(() => {
          spyOn(gl.FilteredSearchTokenizer, 'processTokens')
            .and.callFake(query => ({
                lastToken: {}
              })
            );

          const input = document.createElement('input');
          input.classList.add('filtered-search');
          document.body.appendChild(input);

          expect(input.value).toBe('');
        });

        afterEach(() => {
          document.querySelector('.filtered-search').outerHTML = '';
        });

        it('should add word', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInput().value).toBe('firstWord');
        });

        it('should not add space before first word', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord', true);
          expect(getInput().value).toBe('firstWord');
        });

        it('should not add space before second word by default', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInput().value).toBe('firstWord');
          gl.FilteredSearchDropdownManager.addWordToInput('secondWord');
          expect(getInput().value).toBe('firstWordsecondWord');
        });

        it('should add space before new word when addSpace is passed', () => {
          expect(getInput().value).toBe('');
          gl.FilteredSearchDropdownManager.addWordToInput('firstWord');
          expect(getInput().value).toBe('firstWord');
          gl.FilteredSearchDropdownManager.addWordToInput('secondWord', true);
          expect(getInput().value).toBe('firstWord secondWord');
        });
      });
    });
  });
})();
