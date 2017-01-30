//= require extensions/array
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
      let input;
      const item = {
        title: '@root',
      };

      beforeEach(() => {
        setFixtures(`
          <input type="text" id="test" />
        `);

        input = document.getElementById('test');
      });

      it('should filter without symbol', () => {
        input.value = ':roo';

        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', input, item);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with symbol', () => {
        input.value = '@roo';

        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', input, item);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with colon', () => {
        input.value = 'roo';

        const updatedItem = gl.DropdownUtils.filterWithSymbol('@', input, item);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      describe('filters multiple word title', () => {
        const multipleWordItem = {
          title: 'Community Contributions',
        };

        it('should filter with double quote', () => {
          input.value = 'label:"';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with double quote and symbol', () => {
          input.value = 'label:~"';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with double quote and multiple words', () => {
          input.value = 'label:"community con';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with double quote, symbol and multiple words', () => {
          input.value = 'label:~"community con';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with single quote', () => {
          input.value = 'label:\'';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with single quote and symbol', () => {
          input.value = 'label:~\'';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with single quote and multiple words', () => {
          input.value = 'label:\'community con';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });

        it('should filter with single quote, symbol and multiple words', () => {
          input.value = 'label:~\'community con';

          const updatedItem = gl.DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
          expect(updatedItem.droplab_hidden).toBe(false);
        });
      });
    });

    describe('filterHint', () => {
      let input;

      beforeEach(() => {
        setFixtures(`
          <input type="text" id="test" />
        `);

        input = document.getElementById('test');
      });

      it('should filter', () => {
        input.value = 'l';
        let updatedItem = gl.DropdownUtils.filterHint(input, {
          hint: 'label',
        });
        expect(updatedItem.droplab_hidden).toBe(false);

        input.value = 'o';
        updatedItem = gl.DropdownUtils.filterHint(input, {
          hint: 'label',
        }, 'o');
        expect(updatedItem.droplab_hidden).toBe(true);
      });

      it('should return droplab_hidden false when item has no hint', () => {
        const updatedItem = gl.DropdownUtils.filterHint(input, {}, '');
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

        gl.DropdownUtils.setDataValueIfSelected(null, selected);
        expect(gl.FilteredSearchDropdownManager.addWordToInput.calls.count()).toEqual(1);
      });

      it('returns true when dataValue exists', () => {
        const selected = {
          getAttribute: () => 'value',
        };

        const result = gl.DropdownUtils.setDataValueIfSelected(null, selected);
        expect(result).toBe(true);
      });

      it('returns false when dataValue does not exist', () => {
        const selected = {
          getAttribute: () => null,
        };

        const result = gl.DropdownUtils.setDataValueIfSelected(null, selected);
        expect(result).toBe(false);
      });
    });

    describe('getInputSelectionPosition', () => {
      describe('word with trailing spaces', () => {
        const value = 'label:none ';

        it('should return selectionStart when cursor is at the trailing space', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 11,
            value,
          });

          expect(left).toBe(11);
          expect(right).toBe(11);
        });

        it('should return input when cursor is at the start of input', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 0,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(10);
        });

        it('should return input when cursor is at the middle of input', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 7,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(10);
        });

        it('should return input when cursor is at the end of input', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 10,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(10);
        });
      });

      describe('multiple words', () => {
        const value = 'label:~"Community Contribution"';

        it('should return input when cursor is after the first word', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 17,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(31);
        });

        it('should return input when cursor is before the second word', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 18,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(31);
        });
      });

      describe('incomplete multiple words', () => {
        const value = 'label:~"Community Contribution';

        it('should return entire input when cursor is at the start of input', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 0,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(30);
        });

        it('should return entire input when cursor is at the end of input', () => {
          const { left, right } = gl.DropdownUtils.getInputSelectionPosition({
            selectionStart: 30,
            value,
          });

          expect(left).toBe(0);
          expect(right).toBe(30);
        });
      });
    });
  });
})();
