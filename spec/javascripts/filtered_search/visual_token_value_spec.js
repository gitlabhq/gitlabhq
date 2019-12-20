import _ from 'underscore';
import VisualTokenValue from '~/filtered_search/visual_token_value';
import AjaxCache from '~/lib/utils/ajax_cache';
import UsersCache from '~/lib/utils/users_cache';
import DropdownUtils from '~/filtered_search//dropdown_utils';
import FilteredSearchSpecHelper from '../helpers/filtered_search_spec_helper';

describe('Filtered Search Visual Tokens', () => {
  const findElements = tokenElement => {
    const tokenNameElement = tokenElement.querySelector('.name');
    const tokenValueContainer = tokenElement.querySelector('.value-container');
    const tokenValueElement = tokenValueContainer.querySelector('.value');
    const tokenType = tokenNameElement.innerText.toLowerCase();
    const tokenValue = tokenValueElement.innerText;
    const subject = new VisualTokenValue(tokenValue, tokenType);
    return { subject, tokenValueContainer, tokenValueElement };
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

  describe('updateUserTokenAppearance', () => {
    let usersCacheSpy;

    beforeEach(() => {
      spyOn(UsersCache, 'retrieve').and.callFake(username => usersCacheSpy(username));
    });

    it('ignores error if UsersCache throws', done => {
      spyOn(window, 'Flash');
      const dummyError = new Error('Earth rotated backwards');
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = username => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.reject(dummyError);
      };

      subject
        .updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
        .then(() => {
          expect(window.Flash.calls.count()).toBe(0);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does nothing if user cannot be found', done => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = username => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(undefined);
      };

      subject
        .updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
        .then(() => {
          expect(tokenValueElement.innerText).toBe(tokenValue);
        })
        .then(done)
        .catch(done.fail);
    });

    it('replaces author token with avatar and display name', done => {
      const dummyUser = {
        name: 'Important Person',
        avatar_url: 'https://host.invalid/mypics/avatar.png',
      };
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = username => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      subject
        .updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
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

    it('escapes user name when creating token', done => {
      const dummyUser = {
        name: '<script>',
        avatar_url: `${gl.TEST_HOST}/mypics/avatar.png`,
      };
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = username => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      subject
        .updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue)
        .then(() => {
          expect(tokenValueElement.innerText.trim()).toBe(dummyUser.name);
          tokenValueElement.querySelector('.avatar').remove();

          expect(tokenValueElement.innerHTML.trim()).toBe(_.escape(dummyUser.name));
        })
        .then(done)
        .catch(done.fail);
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

    const missingLabelToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'label',
      '~doesnotexist',
    );
    const spaceLabelToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'label',
      '~"some space"',
    );

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${bugLabelToken.outerHTML}
        ${missingLabelToken.outerHTML}
        ${spaceLabelToken.outerHTML}
      `);

      const filteredSearchInput = document.querySelector('.filtered-search');
      filteredSearchInput.dataset.runnerTagsEndpoint = `${dummyEndpoint}/admin/runners/tag_list`;
      filteredSearchInput.dataset.labelsEndpoint = `${dummyEndpoint}/-/labels`;
      filteredSearchInput.dataset.milestonesEndpoint = `${dummyEndpoint}/-/milestones`;

      AjaxCache.internalStorage = {};
      AjaxCache.internalStorage[`${filteredSearchInput.dataset.labelsEndpoint}.json`] = labelData;
    });

    const parseColor = color => {
      const dummyElement = document.createElement('div');
      dummyElement.style.color = color;
      return dummyElement.style.color;
    };

    const expectValueContainerStyle = (tokenValueContainer, label) => {
      expect(tokenValueContainer.getAttribute('style')).not.toBe(null);
      expect(tokenValueContainer.style.backgroundColor).toBe(parseColor(label.color));
      expect(tokenValueContainer.style.color).toBe(parseColor(label.text_color));
    };

    const findLabel = tokenValue =>
      labelData.find(label => tokenValue === `~${DropdownUtils.getEscapedText(label.title)}`);

    it('updates the color of a label token', done => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      subject
        .updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expectValueContainerStyle(tokenValueContainer, matchingLabel);
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates the color of a label token with spaces', done => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(spaceLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      subject
        .updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expectValueContainerStyle(tokenValueContainer, matchingLabel);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not change color of a missing label', done => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(missingLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      expect(matchingLabel).toBe(undefined);

      subject
        .updateLabelTokenColor(tokenValueContainer, tokenValue)
        .then(() => {
          expect(tokenValueContainer.getAttribute('style')).toBe(null);
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
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'blue', 'white');

      expect(token.style.backgroundColor).toEqual('blue');
      expect(token.style.backgroundColor).not.toEqual(originalBackgroundColor);
    });

    it('should set textColor', () => {
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'white', 'black');

      expect(token.style.color).toEqual('black');
      expect(token.style.color).not.toEqual(originalTextColor);
    });

    it('should add inverted class when textColor is #FFFFFF', () => {
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'black', '#FFFFFF');

      expect(token.style.color).toEqual('rgb(255, 255, 255)');
      expect(token.style.color).not.toEqual(originalTextColor);
      expect(token.querySelector('.remove-token').classList.contains('inverted')).toEqual(true);
    });
  });

  describe('render', () => {
    const setupSpies = subject => {
      spyOn(subject, 'updateLabelTokenColor'); // eslint-disable-line jasmine/no-unsafe-spy
      const updateLabelTokenColorSpy = subject.updateLabelTokenColor;

      spyOn(subject, 'updateUserTokenAppearance'); // eslint-disable-line jasmine/no-unsafe-spy
      const updateUserTokenAppearanceSpy = subject.updateUserTokenAppearance;

      return { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy };
    };

    const keywordToken = FilteredSearchSpecHelper.createFilterVisualToken('search');
    const milestoneToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'milestone',
      'upcoming',
    );

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${authorToken.outerHTML}
        ${bugLabelToken.outerHTML}
        ${keywordToken.outerHTML}
        ${milestoneToken.outerHTML}
      `);
    });

    it('renders a author token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(1);
      const expectedArgs = [tokenValueContainer, tokenValueElement];

      expect(updateUserTokenAppearanceSpy.calls.argsFor(0)).toEqual(expectedArgs);
      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
    });

    it('renders a label token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.calls.count()).toBe(1);
      const expectedArgs = [tokenValueContainer];

      expect(updateLabelTokenColorSpy.calls.argsFor(0)).toEqual(expectedArgs);
      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('renders a milestone token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(milestoneToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('does not update user token appearance for `none` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'none';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('does not update user token appearance for `None` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'None';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('does not update user token appearance for `any` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'any';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.calls.count()).toBe(0);
    });

    it('does not update label token color for `None` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'None';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
    });

    it('does not update label token color for `none` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'none';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
    });

    it('does not update label token color for `any` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'any';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.calls.count()).toBe(0);
    });
  });
});
