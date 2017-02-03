//= require filtered_search/dropdown_utils
//= require filtered_search/filtered_search_tokenizer
//= require filtered_search/filtered_search_dropdown
//= require filtered_search/dropdown_user

(() => {
  describe('Dropdown User', () => {
    describe('getSearchInput', () => {
      let dropdownUser;

      beforeEach(() => {
        spyOn(gl.FilteredSearchDropdown.prototype, 'constructor').and.callFake(() => {});
        spyOn(gl.DropdownUser.prototype, 'getProjectId').and.callFake(() => {});
        spyOn(gl.DropdownUtils, 'getSearchInput').and.callFake(() => {});

        dropdownUser = new gl.DropdownUser();
      });

      it('should not return the double quote found in value', () => {
        spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.returnValue({
          lastToken: {
            value: '"johnny appleseed',
          },
        });

        expect(dropdownUser.getSearchInput()).toBe('johnny appleseed');
      });

      it('should not return the single quote found in value', () => {
        spyOn(gl.FilteredSearchTokenizer, 'processTokens').and.returnValue({
          lastToken: {
            value: '\'larry boy',
          },
        });

        expect(dropdownUser.getSearchInput()).toBe('larry boy');
      });
    });
  });
})();
