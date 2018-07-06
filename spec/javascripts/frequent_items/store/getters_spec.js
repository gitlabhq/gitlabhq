import state from '~/frequent_items/store/state';
import * as getters from '~/frequent_items/store/getters';

describe('Frequent Items Dropdown Store Getters', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('hasSearchQuery', () => {
    it('should return `true` when search query is present', () => {
      mockedState.searchQuery = 'test';

      expect(getters.hasSearchQuery(mockedState)).toBe(true);
    });

    it('should return `false` when search query is empty', () => {
      mockedState.searchQuery = '';

      expect(getters.hasSearchQuery(mockedState)).toBe(false);
    });
  });
});
