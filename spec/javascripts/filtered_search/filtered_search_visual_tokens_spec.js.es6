require('~/filtered_search/filtered_search_visual_tokens');
const FilteredSearchSpecHelper = require('../helpers/filtered_search_spec_helper');

(() => {
  describe('Filtered Search Visual Tokens', () => {
    let tokensContainer;

    beforeEach(() => {
      setFixtures(`
        <ul class="tokens-container">
          ${FilteredSearchSpecHelper.createInputHTML()}
        </ul>
      `);
      tokensContainer = document.querySelector('.tokens-container');
    });

    describe('getLastVisualTokenBeforeInput', () => {
      it('returns when there are no visual tokens', () => {
        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(null);
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there is one visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug'),
        );

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there is an incomplete visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('Author'),
        );

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(false);
      });

      it('returns when there are multiple visual tokens', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
        const items = document.querySelectorAll('.tokens-container .js-visual-token');

        expect(lastVisualToken.isEqualNode(items[items.length - 1])).toEqual(true);
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there are multiple visual tokens and an incomplete visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('assignee')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
        const items = document.querySelectorAll('.tokens-container .js-visual-token');

        expect(lastVisualToken.isEqualNode(items[items.length - 1])).toEqual(true);
        expect(isLastVisualTokenValid).toEqual(false);
      });
    });

    describe('unselectTokens', () => {
      it('does nothing when there are no tokens', () => {
        const beforeHTML = tokensContainer.innerHTML;
        gl.FilteredSearchVisualTokens.unselectTokens();

        expect(tokensContainer.innerHTML).toEqual(beforeHTML);
      });

      it('removes the selected class from buttons', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@author')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '%123', true)}
        `);

        const selected = tokensContainer.querySelector('.js-visual-token .selected');
        expect(selected.classList.contains('selected')).toEqual(true);

        gl.FilteredSearchVisualTokens.unselectTokens();

        expect(selected.classList.contains('selected')).toEqual(false);
      });
    });

    describe('selectToken', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~awesome')}
        `);
      });

      it('removes the selected class if it has selected class', () => {
        const firstTokenButton = tokensContainer.querySelector('.js-visual-token .selectable');
        firstTokenButton.classList.add('selected');

        gl.FilteredSearchVisualTokens.selectToken(firstTokenButton);

        expect(firstTokenButton.classList.contains('selected')).toEqual(false);
      });

      describe('has no selected class', () => {
        it('adds selected class', () => {
          const firstTokenButton = tokensContainer.querySelector('.js-visual-token .selectable');

          gl.FilteredSearchVisualTokens.selectToken(firstTokenButton);

          expect(firstTokenButton.classList.contains('selected')).toEqual(true);
        });

        it('removes selected class from other tokens', () => {
          const tokenButtons = tokensContainer.querySelectorAll('.js-visual-token .selectable');
          tokenButtons[1].classList.add('selected');

          gl.FilteredSearchVisualTokens.selectToken(tokenButtons[0]);

          expect(tokenButtons[0].classList.contains('selected')).toEqual(true);
          expect(tokenButtons[1].classList.contains('selected')).toEqual(false);
        });
      });
    });

    describe('removeSelectedToken', () => {
      it('does not remove when there are no selected tokens', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'none'),
        );

        expect(tokensContainer.querySelector('.js-visual-token .selectable')).not.toEqual(null);

        gl.FilteredSearchVisualTokens.removeSelectedToken();

        expect(tokensContainer.querySelector('.js-visual-token .selectable')).not.toEqual(null);
      });

      it('removes selected token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'none', true),
        );

        expect(tokensContainer.querySelector('.js-visual-token .selectable')).not.toEqual(null);

        gl.FilteredSearchVisualTokens.removeSelectedToken();

        expect(tokensContainer.querySelector('.js-visual-token .selectable')).toEqual(null);
      });
    });

    describe('addVisualTokenElement', () => {
      it('renders search visual tokens', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('search term', null, true);
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-term')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('search term');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('renders filter visual token name', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('milestone');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('renders filter visual token name and value', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('label', 'Frontend');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('label');
        expect(token.querySelector('.value').innerText).toEqual('Frontend');
      });
    });

    describe('addFilterVisualToken', () => {
      it('creates visual token with just tokenName', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('milestone');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('creates visual token with just tokenValue', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('milestone');
        gl.FilteredSearchVisualTokens.addFilterVisualToken('%8.17');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value').innerText).toEqual('%8.17');
      });

      it('creates full visual token', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('assignee', '@john');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('assignee');
        expect(token.querySelector('.value').innerText).toEqual('@john');
      });
    });

    describe('addSearchVisualToken', () => {
      it('creates search visual token', () => {
        gl.FilteredSearchVisualTokens.addSearchVisualToken('search term');
        const token = tokensContainer.querySelector('.js-visual-token');

        expect(token.classList.contains('filtered-search-term')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('search term');
        expect(token.querySelector('.value')).toEqual(null);
      });
    });

    describe('getLastTokenPartial', () => {
      it('should get last token value', () => {
        const value = '~bug';
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', value),
        );

        expect(gl.FilteredSearchVisualTokens.getLastTokenPartial()).toEqual(value);
      });

      it('should get last token name if there is no value', () => {
        const name = 'assignee';
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createNameFilterVisualTokenHTML(name),
        );

        expect(gl.FilteredSearchVisualTokens.getLastTokenPartial()).toEqual(name);
      });

      it('should return empty when there are no tokens', () => {
        expect(gl.FilteredSearchVisualTokens.getLastTokenPartial()).toEqual('');
      });
    });

    describe('removeLastTokenPartial', () => {
      it('should remove the last token value if it exists', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~"Community Contribution"'),
        );

        expect(tokensContainer.querySelector('.js-visual-token .value')).not.toEqual(null);

        gl.FilteredSearchVisualTokens.removeLastTokenPartial();

        expect(tokensContainer.querySelector('.js-visual-token .value')).toEqual(null);
      });

      it('should remove the last token name if there is no value', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('milestone'),
        );

        expect(tokensContainer.querySelector('.js-visual-token .name')).not.toEqual(null);

        gl.FilteredSearchVisualTokens.removeLastTokenPartial();

        expect(tokensContainer.querySelector('.js-visual-token .name')).toEqual(null);
      });

      it('should not remove anything when there are no tokens', () => {
        const html = tokensContainer.innerHTML;
        gl.FilteredSearchVisualTokens.removeLastTokenPartial();

        expect(tokensContainer.innerHTML).toEqual(html);
      });
    });
  });
})();
