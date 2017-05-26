import AjaxCache from '~/lib/utils/ajax_cache';

import '~/filtered_search/filtered_search_visual_tokens';
import FilteredSearchSpecHelper from '../helpers/filtered_search_spec_helper';

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

    describe('input is the last item in tokensContainer', () => {
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

    describe('input is a middle item in tokensContainer', () => {
      it('returns last token before input', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
          ${FilteredSearchSpecHelper.createInputHTML()}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns last partial token before input', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label')}
          ${FilteredSearchSpecHelper.createInputHTML()}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(false);
      });
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

  describe('createVisualTokenElementHTML', () => {
    let tokenElement;

    beforeEach(() => {
      setFixtures(`
        <div class="test-area">
        ${gl.FilteredSearchVisualTokens.createVisualTokenElementHTML()}
        </div>
      `);

      tokenElement = document.querySelector('.test-area').firstElementChild;
    });

    it('contains name div', () => {
      expect(tokenElement.querySelector('.name')).toEqual(jasmine.anything());
    });

    it('contains value container div', () => {
      expect(tokenElement.querySelector('.value-container')).toEqual(jasmine.anything());
    });

    it('contains value div', () => {
      expect(tokenElement.querySelector('.value-container .value')).toEqual(jasmine.anything());
    });

    it('contains selectable class', () => {
      expect(tokenElement.classList.contains('selectable')).toEqual(true);
    });

    it('contains button role', () => {
      expect(tokenElement.getAttribute('role')).toEqual('button');
    });

    describe('remove token', () => {
      it('contains remove-token button', () => {
        expect(tokenElement.querySelector('.value-container .remove-token')).toEqual(jasmine.anything());
      });

      it('contains fa-close icon', () => {
        expect(tokenElement.querySelector('.remove-token .fa-close')).toEqual(jasmine.anything());
      });
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

    it('inserts visual token before input', () => {
      tokensContainer.appendChild(FilteredSearchSpecHelper.createFilterVisualToken('assignee', '@root'));

      gl.FilteredSearchVisualTokens.addVisualTokenElement('label', 'Frontend');
      const tokens = tokensContainer.querySelectorAll('.js-visual-token');
      const labelToken = tokens[0];
      const assigneeToken = tokens[1];

      expect(labelToken.classList.contains('filtered-search-token')).toEqual(true);
      expect(labelToken.querySelector('.name').innerText).toEqual('label');
      expect(labelToken.querySelector('.value').innerText).toEqual('Frontend');

      expect(assigneeToken.classList.contains('filtered-search-token')).toEqual(true);
      expect(assigneeToken.querySelector('.name').innerText).toEqual('assignee');
      expect(assigneeToken.querySelector('.value').innerText).toEqual('@root');
    });
  });

  describe('addValueToPreviousVisualTokenElement', () => {
    it('does not add when previous visual token element has no value', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root'),
      );

      const original = tokensContainer.innerHTML;
      gl.FilteredSearchVisualTokens.addValueToPreviousVisualTokenElement('value');

      expect(original).toEqual(tokensContainer.innerHTML);
    });

    it('does not add when previous visual token element is a search', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
      `);

      const original = tokensContainer.innerHTML;
      gl.FilteredSearchVisualTokens.addValueToPreviousVisualTokenElement('value');

      expect(original).toEqual(tokensContainer.innerHTML);
    });

    it('adds value to previous visual filter token', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label'),
      );

      const original = tokensContainer.innerHTML;
      gl.FilteredSearchVisualTokens.addValueToPreviousVisualTokenElement('value');
      const updatedToken = tokensContainer.querySelector('.js-visual-token');

      expect(updatedToken.querySelector('.name').innerText).toEqual('label');
      expect(updatedToken.querySelector('.value').innerText).toEqual('value');
      expect(original).not.toEqual(tokensContainer.innerHTML);
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

    it('appends to previous search visual token if previous token was a search token', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
      `);

      gl.FilteredSearchVisualTokens.addSearchVisualToken('append this');
      const token = tokensContainer.querySelector('.filtered-search-term');

      expect(token.querySelector('.name').innerText).toEqual('search term append this');
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

  describe('tokenizeInput', () => {
    it('does not do anything if there is no input', () => {
      const original = tokensContainer.innerHTML;
      gl.FilteredSearchVisualTokens.tokenizeInput();

      expect(tokensContainer.innerHTML).toEqual(original);
    });

    it('adds search visual token if previous visual token is valid', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('assignee', 'none'),
      );

      const input = document.querySelector('.filtered-search');
      input.value = 'some value';
      gl.FilteredSearchVisualTokens.tokenizeInput();

      const newToken = tokensContainer.querySelector('.filtered-search-term');

      expect(input.value).toEqual('');
      expect(newToken.querySelector('.name').innerText).toEqual('some value');
      expect(newToken.querySelector('.value')).toEqual(null);
    });

    it('adds value to previous visual token element if previous visual token is invalid', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('assignee'),
      );

      const input = document.querySelector('.filtered-search');
      input.value = '@john';
      gl.FilteredSearchVisualTokens.tokenizeInput();

      const updatedToken = tokensContainer.querySelector('.filtered-search-token');

      expect(input.value).toEqual('');
      expect(updatedToken.querySelector('.name').innerText).toEqual('assignee');
      expect(updatedToken.querySelector('.value').innerText).toEqual('@john');
    });
  });

  describe('editToken', () => {
    let input;
    let token;

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search')}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'upcoming')}
      `);

      input = document.querySelector('.filtered-search');
      token = document.querySelector('.js-visual-token');
    });

    it('tokenize\'s existing input', () => {
      input.value = 'some text';
      spyOn(gl.FilteredSearchVisualTokens, 'tokenizeInput').and.callThrough();

      gl.FilteredSearchVisualTokens.editToken(token);

      expect(gl.FilteredSearchVisualTokens.tokenizeInput).toHaveBeenCalled();
      expect(input.value).not.toEqual('some text');
    });

    it('moves input to the token position', () => {
      expect(tokensContainer.children[3].querySelector('.filtered-search')).not.toEqual(null);

      gl.FilteredSearchVisualTokens.editToken(token);

      expect(tokensContainer.children[1].querySelector('.filtered-search')).not.toEqual(null);
      expect(tokensContainer.children[3].querySelector('.filtered-search')).toEqual(null);
    });

    it('input contains the visual token value', () => {
      gl.FilteredSearchVisualTokens.editToken(token);

      expect(input.value).toEqual('none');
    });

    describe('selected token is a search term token', () => {
      beforeEach(() => {
        token = document.querySelector('.filtered-search-term');
      });

      it('token is removed', () => {
        expect(tokensContainer.querySelector('.filtered-search-term')).not.toEqual(null);

        gl.FilteredSearchVisualTokens.editToken(token);

        expect(tokensContainer.querySelector('.filtered-search-term')).toEqual(null);
      });

      it('input has the same value as removed token', () => {
        expect(input.value).toEqual('');

        gl.FilteredSearchVisualTokens.editToken(token);

        expect(input.value).toEqual('search');
      });
    });
  });

  describe('moveInputTotheRight', () => {
    it('does nothing if the input is already the right most element', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none'),
      );

      spyOn(gl.FilteredSearchVisualTokens, 'tokenizeInput').and.callFake(() => {});
      spyOn(gl.FilteredSearchVisualTokens, 'getLastVisualTokenBeforeInput').and.callThrough();

      gl.FilteredSearchVisualTokens.moveInputToTheRight();

      expect(gl.FilteredSearchVisualTokens.tokenizeInput).toHaveBeenCalled();
      expect(gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput).not.toHaveBeenCalled();
    });

    it('tokenize\'s input', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
      `;

      document.querySelector('.filtered-search').value = 'none';

      gl.FilteredSearchVisualTokens.moveInputToTheRight();
      const value = tokensContainer.querySelector('.js-visual-token .value');

      expect(value.innerText).toEqual('none');
    });

    it('converts input into search term token if last token is valid', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
      `;

      document.querySelector('.filtered-search').value = 'test';

      gl.FilteredSearchVisualTokens.moveInputToTheRight();
      const searchValue = tokensContainer.querySelector('.filtered-search-term .name');

      expect(searchValue.innerText).toEqual('test');
    });

    it('moves the input to the right most element', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~bug')}
      `;

      gl.FilteredSearchVisualTokens.moveInputToTheRight();

      expect(tokensContainer.children[2].querySelector('.filtered-search')).not.toEqual(null);
    });

    it('tokenizes input even if input is the right most element', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label')}
        ${FilteredSearchSpecHelper.createInputHTML('', '~bug')}
      `;

      gl.FilteredSearchVisualTokens.moveInputToTheRight();

      const token = tokensContainer.children[1];
      expect(token.querySelector('.value').innerText).toEqual('~bug');
    });
  });

  describe('renderVisualTokenValue', () => {
    let searchTokens;

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search')}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'upcoming')}
      `);

      searchTokens = document.querySelectorAll('.filtered-search-token');
    });

    it('renders a token value element', () => {
      spyOn(gl.FilteredSearchVisualTokens, 'updateLabelTokenColor');
      const updateLabelTokenColorSpy = gl.FilteredSearchVisualTokens.updateLabelTokenColor;

      expect(searchTokens.length).toBe(2);
      Array.prototype.forEach.call(searchTokens, (token) => {
        updateLabelTokenColorSpy.calls.reset();

        const tokenName = token.querySelector('.name').innerText;
        const tokenValue = 'new value';
        gl.FilteredSearchVisualTokens.renderVisualTokenValue(token, tokenName, tokenValue);

        const tokenValueElement = token.querySelector('.value');
        expect(tokenValueElement.innerText).toBe(tokenValue);

        if (tokenName.toLowerCase() === 'label') {
          const tokenValueContainer = token.querySelector('.value-container');
          expect(updateLabelTokenColorSpy.calls.count()).toBe(1);
          const expectedArgs = [tokenValueContainer, tokenValue];
          expect(updateLabelTokenColorSpy.calls.argsFor(0)).toEqual(expectedArgs);
        } else {
          expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
        }
      });
    });
  });

  describe('updateLabelTokenColor', () => {
    const jsonFixtureName = 'labels/project_labels.json';
    const dummyEndpoint = '/dummy/endpoint';

    preloadFixtures(jsonFixtureName);
    const labelData = getJSONFixture(jsonFixtureName);
    const findLabel = tokenValue => labelData.find(
      label => tokenValue === `~${gl.DropdownUtils.getEscapedText(label.title)}`,
    );

    const bugLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~bug');
    const missingLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~doesnotexist');
    const spaceLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~"some space"');

    const parseColor = (color) => {
      const dummyElement = document.createElement('div');
      dummyElement.style.color = color;
      return dummyElement.style.color;
    };

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${bugLabelToken.outerHTML}
        ${missingLabelToken.outerHTML}
        ${spaceLabelToken.outerHTML}
      `);

      const filteredSearchInput = document.querySelector('.filtered-search');
      filteredSearchInput.dataset.baseEndpoint = dummyEndpoint;

      AjaxCache.internalStorage = { };
      AjaxCache.internalStorage[`${dummyEndpoint}/labels.json`] = labelData;
    });

    const testCase = (token, done) => {
      const tokenValueContainer = token.querySelector('.value-container');
      const tokenValue = token.querySelector('.value').innerText;
      const label = findLabel(tokenValue);

      gl.FilteredSearchVisualTokens.updateLabelTokenColor(tokenValueContainer, tokenValue)
      .then(() => {
        if (label) {
          expect(tokenValueContainer.getAttribute('style')).not.toBe(null);
          expect(tokenValueContainer.style.backgroundColor).toBe(parseColor(label.color));
          expect(tokenValueContainer.style.color).toBe(parseColor(label.text_color));
        } else {
          expect(token).toBe(missingLabelToken);
          expect(tokenValueContainer.getAttribute('style')).toBe(null);
        }
      })
      .then(done)
      .catch(fail);
    };

    it('updates the color of a label token', done => testCase(bugLabelToken, done));
    it('updates the color of a label token with spaces', done => testCase(spaceLabelToken, done));
    it('does not change color of a missing label', done => testCase(missingLabelToken, done));
  });
});
