//= require filtered_search/dropdown_utils
//= require filtered_search/filtered_search_tokenizer
//= require filtered_search/filtered_search_dropdown_manager

(() => {
  describe('Dropdown Utils', () => {
    describe('getEscapedText', () => {
      it('should return same word when it has no space', () => {
        const escaped = gl.DropdownUtils.getEscapedText('textWithoutSpace');
        expect(escaped).toBe('textWithoutSpace');
      });

      it('should escape with double quotes', () => {
        let escaped = gl.DropdownUtils.getEscapedText('text with space');
        expect(escaped).toBe('"text with space"');

        escaped = gl.DropdownUtils.getEscapedText('won\'t fix');
        expect(escaped).toBe('"won\'t fix"');
      });

      it('should escape with single quotes', () => {
        const escaped = gl.DropdownUtils.getEscapedText('won"t fix');
        expect(escaped).toBe('\'won"t fix\'');
      });

      it('should escape with single quotes by default', () => {
        const escaped = gl.DropdownUtils.getEscapedText('won"t\' fix');
        expect(escaped).toBe('\'won"t\' fix\'');
      });
    });

    describe('filterWithSymbol', () => {
      const item = {
        title: '@root',
      };

      beforeEach(() => {
        spyOn(gl.FilteredSearchTokenizer, 'getLastTokenObject')
          .and.callFake(query => ({ value: query }));
      });

      it('should filter without symbol', () => {
        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', item, ':roo');
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with symbol', () => {
        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', item, ':@roo');
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with invalid symbol', () => {
        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', item, ':#');
        expect(updatedItem.droplab_hidden).toBe(true);
      });

      it('should filter with colon', () => {
        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', item, ':');
        expect(updatedItem.droplab_hidden).toBe(false);
      });
    });

    describe('filterMethod', () => {
      beforeEach(() => {
        spyOn(gl.FilteredSearchTokenizer, 'getLastTokenObject')
          .and.callFake(query => ({ value: query }));
      });

      it('should filter by hint', () => {
        let updatedItem = gl.DropdownUtils.filterMethod({
          hint: 'label',
        }, 'l');
        expect(updatedItem.droplab_hidden).toBe(false);

        updatedItem = gl.DropdownUtils.filterMethod({
          hint: 'label',
        }, 'o');
        expect(updatedItem.droplab_hidden).toBe(true);
      });

      it('should return droplab_hidden false when item has no hint', () => {
        const updatedItem = gl.DropdownUtils.filterMethod({}, '');
        expect(updatedItem.droplab_hidden).toBe(false);
      });
    });

    describe('setDataValueIfSelected', () => {
      beforeEach(() => {
        spyOn(gl.FilteredSearchDropdownManager, 'addWordToInput')
          .and.callFake(() => {});
      });

      it('calls addWordToInput when dataValue exists', () => {
        const selected = {
          getAttribute: () => 'value',
        };

        gl.DropdownUtils.setDataValueIfSelected(selected);
        expect(gl.FilteredSearchDropdownManager.addWordToInput.calls.count()).toEqual(1);
      });

      it('returns true when dataValue exists', () => {
        const selected = {
          getAttribute: () => 'value',
        };

        const result = gl.DropdownUtils.setDataValueIfSelected(selected);
        expect(result).toBe(true);
      });

      it('returns false when dataValue does not exist', () => {
        const selected = {
          getAttribute: () => null,
        };

        const result = gl.DropdownUtils.setDataValueIfSelected(selected);
        expect(result).toBe(false);
      });
    });
  });
})();
