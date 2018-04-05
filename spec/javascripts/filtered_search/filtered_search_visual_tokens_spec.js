import _ from 'underscore';
import AjaxCache from '~/lib/utils/ajax_cache';
import UsersCache from '~/lib/utils/users_cache';

import FilteredSearchVisualTokens from '~/filtered_search/filtered_search_visual_tokens';
import DropdownUtils from '~/filtered_search//dropdown_utils';
import FilteredSearchSpecHelper from '../helpers/filtered_search_spec_helper';

describe('Filtered Search Visual Tokens', () => {
  const subject = FilteredSearchVisualTokens;

  const findElements = (tokenElement) => {
    const tokenNameElement = tokenElement.querySelector('.name');
    const tokenValueContainer = tokenElement.querySelector('.value-container');
    const tokenValueElement = tokenValueContainer.querySelector('.value');
    return { tokenNameElement, tokenValueContainer, tokenValueElement };
  };

  let tokensContainer;
  let authorToken;
  let bugLabelToken;

  beforeEach(() => {
    setFixtures(`
      <ul class="tokens-container">
        ${FilteredSearchSpecHelper.createInputHTML()}
      </ul>
    `);
    tokensContainer = document.querySelector('.tokens-container');

    authorToken = FilteredSearchSpecHelper.createFilterVisualToken('author', '@user');
    bugLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~bug');
  });

  describe('getLastVisualTokenBeforeInput', () => {
    it('returns when there are no visual tokens', () => {
      const { lastVisualToken, isLastVisualTokenValid }
        = subject.getLastVisualTokenBeforeInput();

      expect(lastVisualToken).toEqual(null);
      expect(isLastVisualTokenValid).toEqual(true);
    });

    describe('input is the last item in tokensContainer', () => {
      it('returns when there is one visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          bugLabelToken.outerHTML,
        );

        const { lastVisualToken, isLastVisualTokenValid }
          = subject.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there is an incomplete visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('Author'),
        );

        const { lastVisualToken, isLastVisualTokenValid }
          = subject.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(false);
      });

      it('returns when there are multiple visual tokens', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${bugLabelToken.outerHTML}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = subject.getLastVisualTokenBeforeInput();
        const items = document.querySelectorAll('.tokens-container .js-visual-token');

        expect(lastVisualToken.isEqualNode(items[items.length - 1])).toEqual(true);
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there are multiple visual tokens and an incomplete visual token', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${bugLabelToken.outerHTML}
          ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
          ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('assignee')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = subject.getLastVisualTokenBeforeInput();
        const items = document.querySelectorAll('.tokens-container .js-visual-token');

        expect(lastVisualToken.isEqualNode(items[items.length - 1])).toEqual(true);
        expect(isLastVisualTokenValid).toEqual(false);
      });
    });

    describe('input is a middle item in tokensContainer', () => {
      it('returns last token before input', () => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
          ${bugLabelToken.outerHTML}
          ${FilteredSearchSpecHelper.createInputHTML()}
          ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        `);

        const { lastVisualToken, isLastVisualTokenValid }
          = subject.getLastVisualTokenBeforeInput();

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
          = subject.getLastVisualTokenBeforeInput();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(false);
      });
    });
  });

  describe('getEndpointWithQueryParams', () => {
    it('returns `endpoint` string as is when second param `endpointQueryParams` is undefined, null or empty string', () => {
      const endpoint = 'foo/bar/labels.json';
      expect(subject.getEndpointWithQueryParams(endpoint)).toBe(endpoint);
      expect(subject.getEndpointWithQueryParams(endpoint, null)).toBe(endpoint);
      expect(subject.getEndpointWithQueryParams(endpoint, '')).toBe(endpoint);
    });

    it('returns `endpoint` string with values of `endpointQueryParams`', () => {
      const endpoint = 'foo/bar/labels.json';
      const singleQueryParams = '{"foo":"true"}';
      const multipleQueryParams = '{"foo":"true","bar":"true"}';

      expect(subject.getEndpointWithQueryParams(endpoint, singleQueryParams)).toBe(`${endpoint}?foo=true`);
      expect(subject.getEndpointWithQueryParams(endpoint, multipleQueryParams)).toBe(`${endpoint}?foo=true&bar=true`);
    });
  });

  describe('unselectTokens', () => {
    it('does nothing when there are no tokens', () => {
      const beforeHTML = tokensContainer.innerHTML;
      subject.unselectTokens();

      expect(tokensContainer.innerHTML).toEqual(beforeHTML);
    });

    it('removes the selected class from buttons', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@author')}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '%123', true)}
      `);

      const selected = tokensContainer.querySelector('.js-visual-token .selected');
      expect(selected.classList.contains('selected')).toEqual(true);

      subject.unselectTokens();

      expect(selected.classList.contains('selected')).toEqual(false);
    });
  });

  describe('selectToken', () => {
    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${bugLabelToken.outerHTML}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~awesome')}
      `);
    });

    it('removes the selected class if it has selected class', () => {
      const firstTokenButton = tokensContainer.querySelector('.js-visual-token .selectable');
      firstTokenButton.classList.add('selected');

      subject.selectToken(firstTokenButton);

      expect(firstTokenButton.classList.contains('selected')).toEqual(false);
    });

    describe('has no selected class', () => {
      it('adds selected class', () => {
        const firstTokenButton = tokensContainer.querySelector('.js-visual-token .selectable');

        subject.selectToken(firstTokenButton);

        expect(firstTokenButton.classList.contains('selected')).toEqual(true);
      });

      it('removes selected class from other tokens', () => {
        const tokenButtons = tokensContainer.querySelectorAll('.js-visual-token .selectable');
        tokenButtons[1].classList.add('selected');

        subject.selectToken(tokenButtons[0]);

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

      subject.removeSelectedToken();

      expect(tokensContainer.querySelector('.js-visual-token .selectable')).not.toEqual(null);
    });

    it('removes selected token', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', 'none', true),
      );

      expect(tokensContainer.querySelector('.js-visual-token .selectable')).not.toEqual(null);

      subject.removeSelectedToken();

      expect(tokensContainer.querySelector('.js-visual-token .selectable')).toEqual(null);
    });
  });

  describe('createVisualTokenElementHTML', () => {
    let tokenElement;

    beforeEach(() => {
      setFixtures(`
        <div class="test-area">
        ${subject.createVisualTokenElementHTML()}
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
      subject.addVisualTokenElement('search term', null, true);
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-term')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('search term');
      expect(token.querySelector('.value')).toEqual(null);
    });

    it('renders filter visual token name', () => {
      subject.addVisualTokenElement('milestone');
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-token')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('milestone');
      expect(token.querySelector('.value')).toEqual(null);
    });

    it('renders filter visual token name and value', () => {
      subject.addVisualTokenElement('label', 'Frontend');
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-token')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('label');
      expect(token.querySelector('.value').innerText).toEqual('Frontend');
    });

    it('inserts visual token before input', () => {
      tokensContainer.appendChild(FilteredSearchSpecHelper.createFilterVisualToken('assignee', '@root'));

      subject.addVisualTokenElement('label', 'Frontend');
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
      subject.addValueToPreviousVisualTokenElement('value');

      expect(original).toEqual(tokensContainer.innerHTML);
    });

    it('does not add when previous visual token element is a search', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('author', '@root')}
        ${FilteredSearchSpecHelper.createSearchVisualTokenHTML('search term')}
      `);

      const original = tokensContainer.innerHTML;
      subject.addValueToPreviousVisualTokenElement('value');

      expect(original).toEqual(tokensContainer.innerHTML);
    });

    it('adds value to previous visual filter token', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label'),
      );

      const original = tokensContainer.innerHTML;
      subject.addValueToPreviousVisualTokenElement('value');
      const updatedToken = tokensContainer.querySelector('.js-visual-token');

      expect(updatedToken.querySelector('.name').innerText).toEqual('label');
      expect(updatedToken.querySelector('.value').innerText).toEqual('value');
      expect(original).not.toEqual(tokensContainer.innerHTML);
    });
  });

  describe('addFilterVisualToken', () => {
    it('creates visual token with just tokenName', () => {
      subject.addFilterVisualToken('milestone');
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-token')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('milestone');
      expect(token.querySelector('.value')).toEqual(null);
    });

    it('creates visual token with just tokenValue', () => {
      subject.addFilterVisualToken('milestone');
      subject.addFilterVisualToken('%8.17');
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-token')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('milestone');
      expect(token.querySelector('.value').innerText).toEqual('%8.17');
    });

    it('creates full visual token', () => {
      subject.addFilterVisualToken('assignee', '@john');
      const token = tokensContainer.querySelector('.js-visual-token');

      expect(token.classList.contains('filtered-search-token')).toEqual(true);
      expect(token.querySelector('.name').innerText).toEqual('assignee');
      expect(token.querySelector('.value').innerText).toEqual('@john');
    });
  });

  describe('addSearchVisualToken', () => {
    it('creates search visual token', () => {
      subject.addSearchVisualToken('search term');
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

      subject.addSearchVisualToken('append this');
      const token = tokensContainer.querySelector('.filtered-search-term');

      expect(token.querySelector('.name').innerText).toEqual('search term append this');
      expect(token.querySelector('.value')).toEqual(null);
    });
  });

  describe('getLastTokenPartial', () => {
    it('should get last token value', () => {
      const value = '~bug';
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        bugLabelToken.outerHTML,
      );

      expect(subject.getLastTokenPartial()).toEqual(value);
    });

    it('should get last token original value if available', () => {
      const originalValue = '@user';
      const valueContainer = authorToken.querySelector('.value-container');
      valueContainer.dataset.originalValue = originalValue;
      const avatar = document.createElement('img');
      const valueElement = valueContainer.querySelector('.value');
      valueElement.insertAdjacentElement('afterbegin', avatar);
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        authorToken.outerHTML,
      );

      const lastTokenValue = subject.getLastTokenPartial();

      expect(lastTokenValue).toEqual(originalValue);
    });

    it('should get last token name if there is no value', () => {
      const name = 'assignee';
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createNameFilterVisualTokenHTML(name),
      );

      expect(subject.getLastTokenPartial()).toEqual(name);
    });

    it('should return empty when there are no tokens', () => {
      expect(subject.getLastTokenPartial()).toEqual('');
    });
  });

  describe('removeLastTokenPartial', () => {
    it('should remove the last token value if it exists', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '~"Community Contribution"'),
      );

      expect(tokensContainer.querySelector('.js-visual-token .value')).not.toEqual(null);

      subject.removeLastTokenPartial();

      expect(tokensContainer.querySelector('.js-visual-token .value')).toEqual(null);
    });

    it('should remove the last token name if there is no value', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('milestone'),
      );

      expect(tokensContainer.querySelector('.js-visual-token .name')).not.toEqual(null);

      subject.removeLastTokenPartial();

      expect(tokensContainer.querySelector('.js-visual-token .name')).toEqual(null);
    });

    it('should not remove anything when there are no tokens', () => {
      const html = tokensContainer.innerHTML;
      subject.removeLastTokenPartial();

      expect(tokensContainer.innerHTML).toEqual(html);
    });
  });

  describe('tokenizeInput', () => {
    it('does not do anything if there is no input', () => {
      const original = tokensContainer.innerHTML;
      subject.tokenizeInput();

      expect(tokensContainer.innerHTML).toEqual(original);
    });

    it('adds search visual token if previous visual token is valid', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('assignee', 'none'),
      );

      const input = document.querySelector('.filtered-search');
      input.value = 'some value';
      subject.tokenizeInput();

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
      subject.tokenizeInput();

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
      spyOn(subject, 'tokenizeInput').and.callThrough();

      subject.editToken(token);

      expect(subject.tokenizeInput).toHaveBeenCalled();
      expect(input.value).not.toEqual('some text');
    });

    it('moves input to the token position', () => {
      expect(tokensContainer.children[3].querySelector('.filtered-search')).not.toEqual(null);

      subject.editToken(token);

      expect(tokensContainer.children[1].querySelector('.filtered-search')).not.toEqual(null);
      expect(tokensContainer.children[3].querySelector('.filtered-search')).toEqual(null);
    });

    it('input contains the visual token value', () => {
      subject.editToken(token);

      expect(input.value).toEqual('none');
    });

    it('input contains the original value if present', () => {
      const originalValue = '@user';
      const valueContainer = token.querySelector('.value-container');
      valueContainer.dataset.originalValue = originalValue;

      subject.editToken(token);

      expect(input.value).toEqual(originalValue);
    });

    describe('selected token is a search term token', () => {
      beforeEach(() => {
        token = document.querySelector('.filtered-search-term');
      });

      it('token is removed', () => {
        expect(tokensContainer.querySelector('.filtered-search-term')).not.toEqual(null);

        subject.editToken(token);

        expect(tokensContainer.querySelector('.filtered-search-term')).toEqual(null);
      });

      it('input has the same value as removed token', () => {
        expect(input.value).toEqual('');

        subject.editToken(token);

        expect(input.value).toEqual('search');
      });
    });
  });

  describe('moveInputTotheRight', () => {
    it('does nothing if the input is already the right most element', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none'),
      );

      spyOn(subject, 'tokenizeInput').and.callFake(() => {});
      spyOn(subject, 'getLastVisualTokenBeforeInput').and.callThrough();

      subject.moveInputToTheRight();

      expect(subject.tokenizeInput).toHaveBeenCalled();
      expect(subject.getLastVisualTokenBeforeInput).not.toHaveBeenCalled();
    });

    it('tokenize\'s input', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${bugLabelToken.outerHTML}
      `;

      document.querySelector('.filtered-search').value = 'none';

      subject.moveInputToTheRight();
      const value = tokensContainer.querySelector('.js-visual-token .value');

      expect(value.innerText).toEqual('none');
    });

    it('converts input into search term token if last token is valid', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${bugLabelToken.outerHTML}
      `;

      document.querySelector('.filtered-search').value = 'test';

      subject.moveInputToTheRight();
      const searchValue = tokensContainer.querySelector('.filtered-search-term .name');

      expect(searchValue.innerText).toEqual('test');
    });

    it('moves the input to the right most element', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createInputHTML()}
        ${bugLabelToken.outerHTML}
      `;

      subject.moveInputToTheRight();

      expect(tokensContainer.children[2].querySelector('.filtered-search')).not.toEqual(null);
    });

    it('tokenizes input even if input is the right most element', () => {
      tokensContainer.innerHTML = `
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', 'none')}
        ${FilteredSearchSpecHelper.createNameFilterVisualTokenHTML('label')}
        ${FilteredSearchSpecHelper.createInputHTML('', '~bug')}
      `;

      subject.moveInputToTheRight();

      const token = tokensContainer.children[1];
      expect(token.querySelector('.value').innerText).toEqual('~bug');
    });
  });

  describe('renderVisualTokenValue', () => {
    const keywordToken = FilteredSearchSpecHelper.createFilterVisualToken('search');
    const milestoneToken = FilteredSearchSpecHelper.createFilterVisualToken('milestone', 'upcoming');

    let updateLabelTokenColorSpy;
    let updateUserTokenAppearanceSpy;

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${authorToken.outerHTML}
        ${bugLabelToken.outerHTML}
        ${keywordToken.outerHTML}
        ${milestoneToken.outerHTML}
      `);

      spyOn(subject, 'updateLabelTokenColor');
      updateLabelTokenColorSpy = subject.updateLabelTokenColor;

      spyOn(subject, 'updateUserTokenAppearance');
      updateUserTokenAppearanceSpy = subject.updateUserTokenAppearance;
    });

    it('renders a author token value element', () => {
      const { tokenNameElement, tokenValueContainer, tokenValueElement } =
        findElements(authorToken);
      const tokenName = tokenNameElement.innerText;
      const tokenValue = 'new value';

      subject.renderVisualTokenValue(authorToken, tokenName, tokenValue);

      expect(tokenValueElement.innerText).toBe(tokenValue);
      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(1);
      const expectedArgs = [tokenValueContainer, tokenValueElement, tokenValue];
      expect(updateUserTokenAppearanceSpy.calls.argsFor(0)).toEqual(expectedArgs);
      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
    });

    it('renders a label token value element', () => {
      const { tokenNameElement, tokenValueContainer, tokenValueElement } =
        findElements(bugLabelToken);
      const tokenName = tokenNameElement.innerText;
      const tokenValue = 'new value';

      subject.renderVisualTokenValue(bugLabelToken, tokenName, tokenValue);

      expect(tokenValueElement.innerText).toBe(tokenValue);
      expect(updateLabelTokenColorSpy.calls.count()).toBe(1);
      const expectedArgs = [tokenValueContainer, tokenValue];
      expect(updateLabelTokenColorSpy.calls.argsFor(0)).toEqual(expectedArgs);
      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('renders a milestone token value element', () => {
      const { tokenNameElement, tokenValueElement } = findElements(milestoneToken);
      const tokenName = tokenNameElement.innerText;
      const tokenValue = 'new value';

      subject.renderVisualTokenValue(milestoneToken, tokenName, tokenValue);

      expect(tokenValueElement.innerText).toBe(tokenValue);
      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });
  });

  describe('updateUserTokenAppearance', () => {
    let usersCacheSpy;

    beforeEach(() => {
      spyOn(UsersCache, 'retrieve').and.callFake(username => usersCacheSpy(username));
    });

    it('ignores special value "none"', (done) => {
      usersCacheSpy = (username) => {
        expect(username).toBe('none');
        done.fail('Should not resolve "none"!');
      };
      const { tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, 'none')
      .then(done)
      .catch(done.fail);
    });

    it('ignores error if UsersCache throws', (done) => {
      spyOn(window, 'Flash');
      const dummyError = new Error('Earth rotated backwards');
      const { tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.reject(dummyError);
      };

      subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
      .then(() => {
        expect(window.Flash.calls.count()).toBe(0);
      })
      .then(done)
      .catch(done.fail);
    });

    it('does nothing if user cannot be found', (done) => {
      const { tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(undefined);
      };

      subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
      .then(() => {
        expect(tokenValueElement.innerText).toBe(tokenValue);
      })
      .then(done)
      .catch(done.fail);
    });

    it('replaces author token with avatar and display name', (done) => {
      const dummyUser = {
        name: 'Important Person',
        avatar_url: 'https://host.invalid/mypics/avatar.png',
      };
      const { tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
      .then(() => {
        expect(tokenValueContainer.dataset.originalValue).toBe(tokenValue);
        expect(tokenValueElement.innerText.trim()).toBe(dummyUser.name);
        const avatar = tokenValueElement.querySelector('img.avatar');
        expect(avatar.src).toBe(dummyUser.avatar_url);
        expect(avatar.alt).toBe('');
      })
      .then(done)
      .catch(done.fail);
    });

    it('escapes user name when creating token', (done) => {
      const dummyUser = {
        name: '<script>',
        avatar_url: `${gl.TEST_HOST}/mypics/avatar.png`,
      };
      const { tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
      .then(() => {
        expect(tokenValueElement.innerText.trim()).toBe(dummyUser.name);
        tokenValueElement.querySelector('.avatar').remove();
        expect(tokenValueElement.innerHTML.trim()).toBe(_.escape(dummyUser.name));
      })
      .then(done)
      .catch(done.fail);
    });
  });

  describe('setTokenStyle', () => {
    let originalTextColor;

    beforeEach(() => {
      originalTextColor = bugLabelToken.style.color;
    });

    it('should set backgroundColor', () => {
      const originalBackgroundColor = bugLabelToken.style.backgroundColor;
      const token = subject.setTokenStyle(bugLabelToken, 'blue', 'white');
      expect(token.style.backgroundColor).toEqual('blue');
      expect(token.style.backgroundColor).not.toEqual(originalBackgroundColor);
    });

    it('should not set backgroundColor when it is a linear-gradient', () => {
      const token = subject.setTokenStyle(bugLabelToken, 'linear-gradient(135deg, red, blue)', 'white');
      expect(token.style.backgroundColor).toEqual(bugLabelToken.style.backgroundColor);
    });

    it('should set textColor', () => {
      const token = subject.setTokenStyle(bugLabelToken, 'white', 'black');
      expect(token.style.color).toEqual('black');
      expect(token.style.color).not.toEqual(originalTextColor);
    });

    it('should add inverted class when textColor is #FFFFFF', () => {
      const token = subject.setTokenStyle(bugLabelToken, 'black', '#FFFFFF');
      expect(token.style.color).toEqual('rgb(255, 255, 255)');
      expect(token.style.color).not.toEqual(originalTextColor);
      expect(token.querySelector('.remove-token').classList.contains('inverted')).toEqual(true);
    });
  });

  describe('preprocessLabel', () => {
    const endpoint = 'endpoint';

    it('does not preprocess more than once', () => {
      let labels = [];

      spyOn(DropdownUtils, 'duplicateLabelPreprocessing').and.callFake(() => []);

      labels = FilteredSearchVisualTokens.preprocessLabel(endpoint, labels);
      FilteredSearchVisualTokens.preprocessLabel(endpoint, labels);

      expect(DropdownUtils.duplicateLabelPreprocessing.calls.count()).toEqual(1);
    });

    describe('not preprocessed before', () => {
      it('returns preprocessed labels', () => {
        let labels = [];
        expect(labels.preprocessed).not.toEqual(true);
        labels = FilteredSearchVisualTokens.preprocessLabel(endpoint, labels);
        expect(labels.preprocessed).toEqual(true);
      });

      it('overrides AjaxCache with preprocessed results', () => {
        spyOn(AjaxCache, 'override').and.callFake(() => {});
        FilteredSearchVisualTokens.preprocessLabel(endpoint, []);
        expect(AjaxCache.override.calls.count()).toEqual(1);
      });
    });
  });

  describe('updateLabelTokenColor', () => {
    const jsonFixtureName = 'labels/project_labels.json';
    const dummyEndpoint = '/dummy/endpoint';

    preloadFixtures(jsonFixtureName);

    let labelData;

    beforeAll(() => {
      labelData = getJSONFixture(jsonFixtureName);
    });

    const missingLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~doesnotexist');
    const spaceLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '~"some space"');

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

    const parseColor = (color) => {
      const dummyElement = document.createElement('div');
      dummyElement.style.color = color;
      return dummyElement.style.color;
    };

    const expectValueContainerStyle = (tokenValueContainer, label) => {
      expect(tokenValueContainer.getAttribute('style')).not.toBe(null);
      expect(tokenValueContainer.style.backgroundColor).toBe(parseColor(label.color));
      expect(tokenValueContainer.style.color).toBe(parseColor(label.text_color));
    };

    const findLabel = tokenValue => labelData.find(
      label => tokenValue === `~${DropdownUtils.getEscapedText(label.title)}`,
    );

    it('updates the color of a label token', (done) => {
      const { tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      subject.updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expectValueContainerStyle(tokenValueContainer, matchingLabel);
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates the color of a label token with spaces', (done) => {
      const { tokenValueContainer, tokenValueElement } = findElements(spaceLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      subject.updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expectValueContainerStyle(tokenValueContainer, matchingLabel);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not change color of a missing label', (done) => {
      const { tokenValueContainer, tokenValueElement } = findElements(missingLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);
      expect(matchingLabel).toBe(undefined);

      subject.updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expect(tokenValueContainer.getAttribute('style')).toBe(null);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
