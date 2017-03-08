require('~/extensions/array');
require('~/filtered_search/filtered_search_token_keys_with_weights');

(() => {
  describe('Filtered Search Token Keys With Weights', () => {
    const weightTokenKey = {
      key: 'weight',
      type: 'string',
      param: '',
      symbol: '',
    };

    describe('get', () => {
      let tokenKeys;

      beforeEach(() => {
        tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
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
    });

    describe('getConditions', () => {
      let conditions;

      beforeEach(() => {
        conditions = gl.FilteredSearchTokenKeysWithWeights.getConditions();
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
        const tokenKey = gl.FilteredSearchTokenKeysWithWeights.searchByKey('notakey');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by key', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const result = gl.FilteredSearchTokenKeysWithWeights.searchByKey(tokenKeys[0].key);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight key', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysWithWeights.searchByKey(weightTokenKey.key);
        expect(result).toEqual(match);
      });
    });

    describe('searchBySymbol', () => {
      it('should return null when symbol not found', () => {
        const tokenKey = gl.FilteredSearchTokenKeysWithWeights.searchBySymbol('notasymbol');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by symbol', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const result = gl.FilteredSearchTokenKeysWithWeights.searchBySymbol(tokenKeys[0].symbol);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight symbol', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysWithWeights.searchBySymbol(weightTokenKey.symbol);
        expect(result).toEqual(match);
      });
    });

    describe('searchByKeyParam', () => {
      it('should return null when key param not found', () => {
        const tokenKey = gl.FilteredSearchTokenKeysWithWeights.searchByKeyParam('notakeyparam');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return alternative tokenKey when found by key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.getAlternatives();
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysWithWeights.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysWithWeights.searchByKeyParam(weightTokenKey.key);
        expect(result).toEqual(match);
      });
    });

    describe('searchByConditionUrl', () => {
      it('should return null when condition url not found', () => {
        const condition = gl.FilteredSearchTokenKeysWithWeights.searchByConditionUrl(null);
        expect(condition === null).toBe(true);
      });

      it('should return condition when found by url', () => {
        const conditions = gl.FilteredSearchTokenKeysWithWeights.getConditions();
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByConditionUrl(conditions[0].url);
        expect(result).toBe(conditions[0]);
      });

      it('should return weight condition when found by weight url', () => {
        const conditions = gl.FilteredSearchTokenKeysWithWeights.getConditions();
        const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByConditionUrl(weightConditions[0].url);
        expect(result).toBe(weightConditions[0]);
      });
    });

    describe('searchByConditionKeyValue', () => {
      it('should return null when condition tokenKey and value not found', () => {
        const condition = gl.FilteredSearchTokenKeysWithWeights
          .searchByConditionKeyValue(null, null);
        expect(condition === null).toBe(true);
      });

      it('should return condition when found by tokenKey and value', () => {
        const conditions = gl.FilteredSearchTokenKeysWithWeights.getConditions();
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByConditionKeyValue(conditions[0].tokenKey, conditions[0].value);
        expect(result).toEqual(conditions[0]);
      });

      it('should return weight condition when found by weight tokenKey and value', () => {
        const conditions = gl.FilteredSearchTokenKeysWithWeights.getConditions();
        const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
        const result = gl.FilteredSearchTokenKeysWithWeights
          .searchByConditionKeyValue(weightConditions[0].tokenKey, weightConditions[0].value);
        expect(result).toEqual(weightConditions[0]);
      });
    });
  });
})();
