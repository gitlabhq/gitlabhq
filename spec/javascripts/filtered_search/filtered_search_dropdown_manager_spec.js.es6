require('~/extensions/array');
require('~/filtered_search/filtered_search_visual_tokens');
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
        // spyOn(gl.FilteredSearchVisualTokens, 'addVisualToken').and.callFake(() => {});
        const div = document.createElement('div');
        // div.classList.add('spec-container');

        div.innerHTML = `
          <ul class="tokens-container"></ul>
          <input class="filtered-search">
        `;
        document.body.appendChild(div);
      });

      afterEach(() => {
        document.querySelector('.filtered-search').outerHTML = '';
        document.querySelector('.tokens-container').innerHTML = '';
      });

      describe('input has no existing value', () => {
        it('should add just tokenName', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('milestone');

          const tokensContainer = document.querySelector('.tokens-container');
          const token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('milestone');
          expect(getInputValue()).toBe('');
        });

        it('should add tokenName and tokenValue', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('label');

          const tokensContainer = document.querySelector('.tokens-container');
          let token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('label');
          expect(getInputValue()).toBe('');

          gl.FilteredSearchDropdownManager.addWordToInput('label', 'none');
          // We have to get that reference again
          // Because gl.FilteredSearchDropdownManager deletes the previous token
          token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('label');
          expect(token.querySelector('.value').innerText).toBe('none');
          expect(getInputValue()).toBe('');
        });
      });

      describe('input has existing value', () => {
        it('should be able to just add tokenName', () => {
          setInputValue('a');
          gl.FilteredSearchDropdownManager.addWordToInput('author');

          const tokensContainer = document.querySelector('.tokens-container');
          const token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('author');
          expect(getInputValue()).toBe('');
        });

        it('should replace tokenValue', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('author');

          setInputValue('roo');
          gl.FilteredSearchDropdownManager.addWordToInput(null, '@root');

          const tokensContainer = document.querySelector('.tokens-container');
          const token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('author');
          expect(token.querySelector('.value').innerText).toBe('@root');
          expect(getInputValue()).toBe('');
        });

        it('should add tokenValues containing spaces', () => {
          gl.FilteredSearchDropdownManager.addWordToInput('label');

          setInputValue('"test ');
          gl.FilteredSearchDropdownManager.addWordToInput('label', '~\'"test me"\'');

          const tokensContainer = document.querySelector('.tokens-container');
          const token = tokensContainer.children[0];

          expect(tokensContainer.children.length).toBe(1);
          expect(token.classList.contains('js-visual-token')).toEqual(true);
          expect(token.classList.contains('filtered-search-token')).toEqual(true);
          expect(token.querySelector('.name').innerText).toBe('label');
          expect(token.querySelector('.value').innerText).toBe('~\'"test me"\'');
          expect(getInputValue()).toBe('');
        });
      });
    });
  });
})();
