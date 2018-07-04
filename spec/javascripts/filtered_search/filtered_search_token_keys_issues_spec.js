import FilteredSearchTokenKeysIssues from 'ee/filtered_search/filtered_search_token_keys_issues';

describe('Filtered Search Token Keys (Issues EE)', () => {
  const weightTokenKey = {
    key: 'weight',
    type: 'string',
    param: '',
    symbol: '',
    icon: 'balance-scale',
    tag: 'number',
  };

  describe('get', () => {
    let tokenKeys;

    beforeEach(() => {
      FilteredSearchTokenKeysIssues.init({
        multipleAssignees: true,
      });
      tokenKeys = FilteredSearchTokenKeysIssues.get();
    });

    it('should return tokenKeys', () => {
      expect(tokenKeys !== null).toBe(true);
    });

    it('should return tokenKeys as an array', () => {
      expect(tokenKeys instanceof Array).toBe(true);
    });

    it('should return weightTokenKey as part of tokenKeys', () => {
      const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
      expect(match).toEqual(weightTokenKey);
    });

    it('should always return the same array', () => {
      const tokenKeys2 = FilteredSearchTokenKeysIssues.get();

      expect(tokenKeys).toEqual(tokenKeys2);
    });

    it('should return assignee as an array', () => {
      const assignee = tokenKeys.find(tokenKey => tokenKey.key === 'assignee');
      expect(assignee.type).toEqual('array');
    });
  });

  describe('getKeys', () => {
    it('should return keys', () => {
      const getKeys = FilteredSearchTokenKeysIssues.getKeys();
      const keys = FilteredSearchTokenKeysIssues.get().map(i => i.key);

      keys.forEach((key, i) => {
        expect(key).toEqual(getKeys[i]);
      });
    });
  });

  describe('getConditions', () => {
    let conditions;

    beforeEach(() => {
      conditions = FilteredSearchTokenKeysIssues.getConditions();
    });

    it('should return conditions', () => {
      expect(conditions !== null).toBe(true);
    });

    it('should return conditions as an array', () => {
      expect(conditions instanceof Array).toBe(true);
    });

    it('should return weightConditions as part of conditions', () => {
      const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
      expect(weightConditions.length).toBe(2);
    });
  });

  describe('searchByKey', () => {
    it('should return null when key not found', () => {
      const tokenKey = FilteredSearchTokenKeysIssues.searchByKey('notakey');
      expect(tokenKey === null).toBe(true);
    });

    it('should return tokenKey when found by key', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const result = FilteredSearchTokenKeysIssues.searchByKey(tokenKeys[0].key);
      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return weight tokenKey when found by weight key', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
      const result = FilteredSearchTokenKeysIssues.searchByKey(weightTokenKey.key);
      expect(result).toEqual(match);
    });
  });

  describe('searchBySymbol', () => {
    it('should return null when symbol not found', () => {
      const tokenKey = FilteredSearchTokenKeysIssues.searchBySymbol('notasymbol');
      expect(tokenKey === null).toBe(true);
    });

    it('should return tokenKey when found by symbol', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const result = FilteredSearchTokenKeysIssues.searchBySymbol(tokenKeys[0].symbol);
      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return weight tokenKey when found by weight symbol', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
      const result = FilteredSearchTokenKeysIssues.searchBySymbol(weightTokenKey.symbol);
      expect(result).toEqual(match);
    });
  });

  describe('searchByKeyParam', () => {
    it('should return null when key param not found', () => {
      const tokenKey = FilteredSearchTokenKeysIssues.searchByKeyParam('notakeyparam');
      expect(tokenKey === null).toBe(true);
    });

    it('should return tokenKey when found by key param', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const result = FilteredSearchTokenKeysIssues
        .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return alternative tokenKey when found by key param', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.getAlternatives();
      const result = FilteredSearchTokenKeysIssues
        .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return weight tokenKey when found by weight key param', () => {
      const tokenKeys = FilteredSearchTokenKeysIssues.get();
      const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
      const result = FilteredSearchTokenKeysIssues.searchByKeyParam(weightTokenKey.key);
      expect(result).toEqual(match);
    });
  });

  describe('searchByConditionUrl', () => {
    it('should return null when condition url not found', () => {
      const condition = FilteredSearchTokenKeysIssues.searchByConditionUrl(null);
      expect(condition === null).toBe(true);
    });

    it('should return condition when found by url', () => {
      const conditions = FilteredSearchTokenKeysIssues.getConditions();
      const result = FilteredSearchTokenKeysIssues
        .searchByConditionUrl(conditions[0].url);
      expect(result).toBe(conditions[0]);
    });

    it('should return weight condition when found by weight url', () => {
      const conditions = FilteredSearchTokenKeysIssues.getConditions();
      const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
      const result = FilteredSearchTokenKeysIssues
        .searchByConditionUrl(weightConditions[0].url);
      expect(result).toBe(weightConditions[0]);
    });
  });

  describe('searchByConditionKeyValue', () => {
    it('should return null when condition tokenKey and value not found', () => {
      const condition = FilteredSearchTokenKeysIssues
        .searchByConditionKeyValue(null, null);
      expect(condition === null).toBe(true);
    });

    it('should return condition when found by tokenKey and value', () => {
      const conditions = FilteredSearchTokenKeysIssues.getConditions();
      const result = FilteredSearchTokenKeysIssues
        .searchByConditionKeyValue(conditions[0].tokenKey, conditions[0].value);
      expect(result).toEqual(conditions[0]);
    });

    it('should return weight condition when found by weight tokenKey and value', () => {
      const conditions = FilteredSearchTokenKeysIssues.getConditions();
      const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
      const result = FilteredSearchTokenKeysIssues
        .searchByConditionKeyValue(weightConditions[0].tokenKey, weightConditions[0].value);
      expect(result).toEqual(weightConditions[0]);
    });
  });
});
