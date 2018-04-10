import DropdownUtils from '~/filtered_search/dropdown_utils';
import FilteredSearchDropdownManager from '~/filtered_search/filtered_search_dropdown_manager';
import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import FilteredSearchSpecHelper from '../helpers/filtered_search_spec_helper';

describe('Dropdown Utils', () => {
  const issueListFixture = 'issues/issue_list.html.raw';
  preloadFixtures(issueListFixture);

  describe('getEscapedText', () => {
    it('should return same word when it has no space', () => {
      const escaped = DropdownUtils.getEscapedText('textWithoutSpace');
      expect(escaped).toBe('textWithoutSpace');
    });

    it('should escape with double quotes', () => {
      let escaped = DropdownUtils.getEscapedText('text with space');
      expect(escaped).toBe('"text with space"');

      escaped = DropdownUtils.getEscapedText('won\'t fix');
      expect(escaped).toBe('"won\'t fix"');
    });

    it('should escape with single quotes', () => {
      const escaped = DropdownUtils.getEscapedText('won"t fix');
      expect(escaped).toBe('\'won"t fix\'');
    });

    it('should escape with single quotes by default', () => {
      const escaped = DropdownUtils.getEscapedText('won"t\' fix');
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
      input.value = 'roo';

      const updatedItem = DropdownUtils.filterWithSymbol('@', input, item);
      expect(updatedItem.droplab_hidden).toBe(false);
    });

    it('should filter with symbol', () => {
      input.value = '@roo';

      const updatedItem = DropdownUtils.filterWithSymbol('@', input, item);
      expect(updatedItem.droplab_hidden).toBe(false);
    });

    describe('filters multiple word title', () => {
      const multipleWordItem = {
        title: 'Community Contributions',
      };

      it('should filter with double quote', () => {
        input.value = '"';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with double quote and symbol', () => {
        input.value = '~"';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with double quote and multiple words', () => {
        input.value = '"community con';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with double quote, symbol and multiple words', () => {
        input.value = '~"community con';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with single quote', () => {
        input.value = '\'';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with single quote and symbol', () => {
        input.value = '~\'';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with single quote and multiple words', () => {
        input.value = '\'community con';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });

      it('should filter with single quote, symbol and multiple words', () => {
        input.value = '~\'community con';

        const updatedItem = DropdownUtils.filterWithSymbol('~', input, multipleWordItem);
        expect(updatedItem.droplab_hidden).toBe(false);
      });
    });
  });

  describe('filterHint', () => {
    let input;
    let allowedKeys;

    beforeEach(() => {
      setFixtures(`
        <ul class="tokens-container">
          <li class="input-token">
            <input class="filtered-search" type="text" id="test" />
          </li>
        </ul>
      `);

      input = document.getElementById('test');
      allowedKeys = FilteredSearchTokenKeys.getKeys();
    });

    function config() {
      return {
        input,
        allowedKeys,
      };
    }

    it('should filter', () => {
      input.value = 'l';
      let updatedItem = DropdownUtils.filterHint(config(), {
        hint: 'label',
      });
      expect(updatedItem.droplab_hidden).toBe(false);

      input.value = 'o';
      updatedItem = DropdownUtils.filterHint(config(), {
        hint: 'label',
      });
      expect(updatedItem.droplab_hidden).toBe(true);
    });

    it('should return droplab_hidden false when item has no hint', () => {
      const updatedItem = DropdownUtils.filterHint(config(), {}, '');
      expect(updatedItem.droplab_hidden).toBe(false);
    });

    it('should allow multiple if item.type is array', () => {
      input.value = 'label:~first la';
      const updatedItem = DropdownUtils.filterHint(config(), {
        hint: 'label',
        type: 'array',
      });
      expect(updatedItem.droplab_hidden).toBe(false);
    });

    it('should prevent multiple if item.type is not array', () => {
      input.value = 'milestone:~first mile';
      let updatedItem = DropdownUtils.filterHint(config(), {
        hint: 'milestone',
      });
      expect(updatedItem.droplab_hidden).toBe(true);

      updatedItem = DropdownUtils.filterHint(config(), {
        hint: 'milestone',
        type: 'string',
      });
      expect(updatedItem.droplab_hidden).toBe(true);
    });
  });

  describe('mergeDuplicateLabels', () => {
    const dataMap = {
      label: {
        title: 'label',
        color: '#FFFFFF',
      },
    };

    it('should add label to dataMap if it is not a duplicate', () => {
      const newLabel = {
        title: 'new-label',
        color: '#000000',
      };

      const updated = DropdownUtils.mergeDuplicateLabels(dataMap, newLabel);
      expect(updated[newLabel.title]).toEqual(newLabel);
    });

    it('should merge colors if label is a duplicate', () => {
      const duplicate = {
        title: 'label',
        color: '#000000',
      };

      const updated = DropdownUtils.mergeDuplicateLabels(dataMap, duplicate);
      expect(updated.label.multipleColors).toEqual([dataMap.label.color, duplicate.color]);
    });
  });

  describe('duplicateLabelColor', () => {
    it('should linear-gradient 2 colors', () => {
      const gradient = DropdownUtils.duplicateLabelColor(['#FFFFFF', '#000000']);
      expect(gradient).toEqual('linear-gradient(#FFFFFF 0%, #FFFFFF 50%, #000000 50%, #000000 100%)');
    });

    it('should linear-gradient 3 colors', () => {
      const gradient = DropdownUtils.duplicateLabelColor(['#FFFFFF', '#000000', '#333333']);
      expect(gradient).toEqual('linear-gradient(#FFFFFF 0%, #FFFFFF 33%, #000000 33%, #000000 66%, #333333 66%, #333333 100%)');
    });

    it('should linear-gradient 4 colors', () => {
      const gradient = DropdownUtils.duplicateLabelColor(['#FFFFFF', '#000000', '#333333', '#DDDDDD']);
      expect(gradient).toEqual('linear-gradient(#FFFFFF 0%, #FFFFFF 25%, #000000 25%, #000000 50%, #333333 50%, #333333 75%, #DDDDDD 75%, #DDDDDD 100%)');
    });

    it('should not linear-gradient more than 4 colors', () => {
      const gradient = DropdownUtils.duplicateLabelColor(['#FFFFFF', '#000000', '#333333', '#DDDDDD', '#EEEEEE']);
      expect(gradient.indexOf('#EEEEEE') === -1).toEqual(true);
    });
  });

  describe('duplicateLabelPreprocessing', () => {
    it('should set preprocessed to true', () => {
      const results = DropdownUtils.duplicateLabelPreprocessing([]);
      expect(results.preprocessed).toEqual(true);
    });

    it('should not mutate existing data if there are no duplicates', () => {
      const data = [{
        title: 'label1',
        color: '#FFFFFF',
      }, {
        title: 'label2',
        color: '#000000',
      }];
      const results = DropdownUtils.duplicateLabelPreprocessing(data);

      expect(results.length).toEqual(2);
      expect(results[0]).toEqual(data[0]);
      expect(results[1]).toEqual(data[1]);
    });

    describe('duplicate labels', () => {
      const data = [{
        title: 'label',
        color: '#FFFFFF',
      }, {
        title: 'label',
        color: '#000000',
      }];
      const results = DropdownUtils.duplicateLabelPreprocessing(data);

      it('should merge duplicate labels', () => {
        expect(results.length).toEqual(1);
      });

      it('should convert multiple colored labels into linear-gradient', () => {
        expect(results[0].color).toEqual(DropdownUtils.duplicateLabelColor(['#FFFFFF', '#000000']));
      });

      it('should set multiple colored label text color to black', () => {
        expect(results[0].text_color).toEqual('#000000');
      });
    });
  });

  describe('setDataValueIfSelected', () => {
    beforeEach(() => {
      spyOn(FilteredSearchDropdownManager, 'addWordToInput')
        .and.callFake(() => {});
    });

    it('calls addWordToInput when dataValue exists', () => {
      const selected = {
        getAttribute: () => 'value',
      };

      DropdownUtils.setDataValueIfSelected(null, selected);
      expect(FilteredSearchDropdownManager.addWordToInput.calls.count()).toEqual(1);
    });

    it('returns true when dataValue exists', () => {
      const selected = {
        getAttribute: () => 'value',
      };

      const result = DropdownUtils.setDataValueIfSelected(null, selected);
      expect(result).toBe(true);
    });

    it('returns false when dataValue does not exist', () => {
      const selected = {
        getAttribute: () => null,
      };

      const result = DropdownUtils.setDataValueIfSelected(null, selected);
      expect(result).toBe(false);
    });
  });

  describe('getInputSelectionPosition', () => {
    describe('word with trailing spaces', () => {
      const value = 'label:none ';

      it('should return selectionStart when cursor is at the trailing space', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 11,
          value,
        });

        expect(left).toBe(11);
        expect(right).toBe(11);
      });

      it('should return input when cursor is at the start of input', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 0,
          value,
        });

        expect(left).toBe(0);
        expect(right).toBe(10);
      });

      it('should return input when cursor is at the middle of input', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 7,
          value,
        });

        expect(left).toBe(0);
        expect(right).toBe(10);
      });

      it('should return input when cursor is at the end of input', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
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
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 17,
          value,
        });

        expect(left).toBe(0);
        expect(right).toBe(31);
      });

      it('should return input when cursor is before the second word', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
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
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 0,
          value,
        });

        expect(left).toBe(0);
        expect(right).toBe(30);
      });

      it('should return entire input when cursor is at the end of input', () => {
        const { left, right } = DropdownUtils.getInputSelectionPosition({
          selectionStart: 30,
          value,
        });

        expect(left).toBe(0);
        expect(right).toBe(30);
      });
    });
  });

  describe('getSearchQuery', () => {
    let authorToken;

    beforeEach(() => {
      loadFixtures(issueListFixture);

      authorToken = FilteredSearchSpecHelper.createFilterVisualToken('author', '@user');
      const searchTermToken = FilteredSearchSpecHelper.createSearchVisualToken('search term');

      const tokensContainer = document.querySelector('.tokens-container');
      tokensContainer.appendChild(searchTermToken);
      tokensContainer.appendChild(authorToken);
    });

    it('uses original value if present', () => {
      const originalValue = 'original dance';
      const valueContainer = authorToken.querySelector('.value-container');
      valueContainer.dataset.originalValue = originalValue;

      const searchQuery = DropdownUtils.getSearchQuery();

      expect(searchQuery).toBe(' search term author:original dance');
    });
  });
});
