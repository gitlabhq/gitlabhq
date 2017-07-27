import '~/extensions/array';
import '~/filtered_search/filtered_search_token_keys_issues_ee';

(() => {
  describe('Filtered Search Token Keys (Issues EE)', () => {
    const weightTokenKey = {
      key: 'weight',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'balance-scale',
    };

    describe('get', () => {
      let tokenKeys;

      beforeEach(() => {
        gl.FilteredSearchTokenKeysIssuesEE.init({
          multipleAssignees: true,
        });
        tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
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
        const tokenKeys2 = gl.FilteredSearchTokenKeysIssuesEE.get();

        expect(tokenKeys).toEqual(tokenKeys2);
      });

      it('should return assignee as an array', () => {
        const assignee = tokenKeys.find(tokenKey => tokenKey.key === 'assignee');
        expect(assignee.type).toEqual('array');
      });
    });

    describe('getKeys', () => {
      it('should return keys', () => {
        const getKeys = gl.FilteredSearchTokenKeysIssuesEE.getKeys();
        const keys = gl.FilteredSearchTokenKeysIssuesEE.get().map(i => i.key);

        keys.forEach((key, i) => {
          expect(key).toEqual(getKeys[i]);
        });
      });
    });

    describe('getConditions', () => {
      let conditions;

      beforeEach(() => {
        conditions = gl.FilteredSearchTokenKeysIssuesEE.getConditions();
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
        const tokenKey = gl.FilteredSearchTokenKeysIssuesEE.searchByKey('notakey');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by key', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const result = gl.FilteredSearchTokenKeysIssuesEE.searchByKey(tokenKeys[0].key);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight key', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysIssuesEE.searchByKey(weightTokenKey.key);
        expect(result).toEqual(match);
      });
    });

    describe('searchBySymbol', () => {
      it('should return null when symbol not found', () => {
        const tokenKey = gl.FilteredSearchTokenKeysIssuesEE.searchBySymbol('notasymbol');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by symbol', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const result = gl.FilteredSearchTokenKeysIssuesEE.searchBySymbol(tokenKeys[0].symbol);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight symbol', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysIssuesEE.searchBySymbol(weightTokenKey.symbol);
        expect(result).toEqual(match);
      });
    });

    describe('searchByKeyParam', () => {
      it('should return null when key param not found', () => {
        const tokenKey = gl.FilteredSearchTokenKeysIssuesEE.searchByKeyParam('notakeyparam');
        expect(tokenKey === null).toBe(true);
      });

      it('should return tokenKey when found by key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return alternative tokenKey when found by key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.getAlternatives();
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByKeyParam(`${tokenKeys[0].key}_${tokenKeys[0].param}`);
        expect(result).toEqual(tokenKeys[0]);
      });

      it('should return weight tokenKey when found by weight key param', () => {
        const tokenKeys = gl.FilteredSearchTokenKeysIssuesEE.get();
        const match = tokenKeys.find(tk => tk.key === weightTokenKey.key);
        const result = gl.FilteredSearchTokenKeysIssuesEE.searchByKeyParam(weightTokenKey.key);
        expect(result).toEqual(match);
      });
    });

    describe('searchByConditionUrl', () => {
      it('should return null when condition url not found', () => {
        const condition = gl.FilteredSearchTokenKeysIssuesEE.searchByConditionUrl(null);
        expect(condition === null).toBe(true);
      });

      it('should return condition when found by url', () => {
        const conditions = gl.FilteredSearchTokenKeysIssuesEE.getConditions();
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByConditionUrl(conditions[0].url);
        expect(result).toBe(conditions[0]);
      });

      it('should return weight condition when found by weight url', () => {
        const conditions = gl.FilteredSearchTokenKeysIssuesEE.getConditions();
        const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByConditionUrl(weightConditions[0].url);
        expect(result).toBe(weightConditions[0]);
      });
    });

    describe('searchByConditionKeyValue', () => {
      it('should return null when condition tokenKey and value not found', () => {
        const condition = gl.FilteredSearchTokenKeysIssuesEE
          .searchByConditionKeyValue(null, null);
        expect(condition === null).toBe(true);
      });

      it('should return condition when found by tokenKey and value', () => {
        const conditions = gl.FilteredSearchTokenKeysIssuesEE.getConditions();
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByConditionKeyValue(conditions[0].tokenKey, conditions[0].value);
        expect(result).toEqual(conditions[0]);
      });

      it('should return weight condition when found by weight tokenKey and value', () => {
        const conditions = gl.FilteredSearchTokenKeysIssuesEE.getConditions();
        const weightConditions = conditions.filter(c => c.tokenKey === 'weight');
        const result = gl.FilteredSearchTokenKeysIssuesEE
          .searchByConditionKeyValue(weightConditions[0].tokenKey, weightConditions[0].value);
        expect(result).toEqual(weightConditions[0]);
      });
    });
  });
})();
