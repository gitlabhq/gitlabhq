import '~/filtered_search/dropdown_utils';
import '~/filtered_search/filtered_search_tokenizer';
import '~/filtered_search/filtered_search_dropdown';
import '~/filtered_search/dropdown_user';

describe('Dropdown User', () => {
  describe('getSearchInput', () => {
    let dropdownUser;

    beforeEach(() => {
      spyOn(gl.DropdownUser.prototype, 'bindEvents').and.callFake(() => {});
      spyOn(gl.DropdownUser.prototype, 'getProjectId').and.callFake(() => {});
      spyOn(gl.DropdownUtils, 'getSearchInput').and.callFake(() => {});

      dropdownUser = new gl.DropdownUser({
        tokenKeys: gl.FilteredSearchTokenKeys,
      });
    });

    it('should not return the double quote found in value', () => {
      spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.returnValue({
        lastToken: '"johnny appleseed',
      });

      expect(dropdownUser.getSearchInput()).toBe('johnny appleseed');
    });

    it('should not return the single quote found in value', () => {
      spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.returnValue({
        lastToken: '\'larry boy',
      });

      expect(dropdownUser.getSearchInput()).toBe('larry boy');
    });
  });

  describe('config AjaxFilter\'s endpoint', () => {
    beforeEach(() => {
      spyOn(gl.DropdownUser.prototype, 'bindEvents').and.callFake(() => {});
      spyOn(gl.DropdownUser.prototype, 'getProjectId').and.callFake(() => {});
    });

    it('should return endpoint', () => {
      window.gon = {
        relative_url_root: '',
      };
      const dropdown = new gl.DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe('/autocomplete/users.json');
    });

    it('should return endpoint when relative_url_root is undefined', () => {
      const dropdown = new gl.DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe('/autocomplete/users.json');
    });

    it('should return endpoint with relative url when available', () => {
      window.gon = {
        relative_url_root: '/gitlab_directory',
      };
      const dropdown = new gl.DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe('/gitlab_directory/autocomplete/users.json');
    });

    afterEach(() => {
      window.gon = {};
    });
  });

  describe('hideCurrentUser', () => {
    const fixtureTemplate = 'issues/issue_list.html.raw';
    preloadFixtures(fixtureTemplate);

    let dropdown;
    let authorFilterDropdownElement;

    beforeEach(() => {
      loadFixtures(fixtureTemplate);
      authorFilterDropdownElement = document.querySelector('#js-dropdown-author');
      const dummyInput = document.createElement('div');
      dropdown = new gl.DropdownUser({
        dropdown: authorFilterDropdownElement,
        input: dummyInput,
      });
    });

    const findCurrentUserElement = () => authorFilterDropdownElement.querySelector('.js-current-user');

    it('hides the current user from dropdown', () => {
      const currentUserElement = findCurrentUserElement();
      expect(currentUserElement).not.toBe(null);

      dropdown.hideCurrentUser();

      expect(currentUserElement.classList).toContain('hidden');
    });

    it('does nothing if no user is logged in', () => {
      const currentUserElement = findCurrentUserElement();
      currentUserElement.parentNode.removeChild(currentUserElement);
      expect(findCurrentUserElement()).toBe(null);

      dropdown.hideCurrentUser();
    });
  });
});
