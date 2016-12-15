//= require extensions/array
//= require filtered_search/filtered_search_token_keys
//= require filtered_search/filtered_search_tokenizer

(() => {
  describe('Filtered Search Tokenizer', () => {
    describe('parseToken', () => {
      it('should return key, value and symbol', () => {
        const { tokenKey, tokenValue, tokenSymbol } = gl.FilteredSearchTokenizer
          .parseToken('author:@user');

        expect(tokenKey).toBe('author');
        expect(tokenValue).toBe('@user');
        expect(tokenSymbol).toBe('@');
      });

      it('should return value with spaces', () => {
        const { tokenKey, tokenValue, tokenSymbol } = gl.FilteredSearchTokenizer
          .parseToken('label:~"test me"');

        expect(tokenKey).toBe('label');
        expect(tokenValue).toBe('~"test me"');
        expect(tokenSymbol).toBe('~');
      });
    });

    describe('getLastTokenObject', () => {
      beforeEach(() => {
        spyOn(gl.FilteredSearchTokenizer, 'getLastToken').and.callFake(input => input);
      });

      it('should return key and value', () => {
        const { key, value } = gl.FilteredSearchTokenizer.getLastTokenObject('author:@root');
        expect(key).toBe('author');
        expect(value).toBe(':@root');
      });

      describe('string without colon', () => {
        let lastTokenObject;

        beforeEach(() => {
          lastTokenObject = gl.FilteredSearchTokenizer.getLastTokenObject('author');
        });

        it('should return key as an empty string', () => {
          expect(lastTokenObject.key).toBe('');
        });

        it('should return input as value', () => {
          expect(lastTokenObject.value).toBe('author');
        });
      });
    });

    describe('getLastToken', () => {
      it('returns entire string when there is only one word', () => {
        const lastToken = gl.FilteredSearchTokenizer.getLastToken('input');
        expect(lastToken).toBe('input');
      });

      it('returns last word when there are multiple words', () => {
        const lastToken = gl.FilteredSearchTokenizer.getLastToken('this is a few words');
        expect(lastToken).toBe('words');
      });

      it('returns last token when there are multiple tokens', () => {
        const lastToken = gl.FilteredSearchTokenizer
          .getLastToken('label:fun author:root milestone:2.0');
        expect(lastToken).toBe('milestone:2.0');
      });

      it('returns last token containing spaces escaped by double quotes', () => {
        const lastToken = gl.FilteredSearchTokenizer
          .getLastToken('label:fun author:root milestone:2.0 label:~"Feature Proposal"');
        expect(lastToken).toBe('label:~"Feature Proposal"');
      });

      it('returns last token containing spaces escaped by single quotes', () => {
        const lastToken = gl.FilteredSearchTokenizer
          .getLastToken('label:fun author:root milestone:2.0 label:~\'Feature Proposal\'');
        expect(lastToken).toBe('label:~\'Feature Proposal\'');
      });

      it('returns last token containing special characters', () => {
        const lastToken = gl.FilteredSearchTokenizer
          .getLastToken('label:fun author:root milestone:2.0 label:~!@#$%^&*()');
        expect(lastToken).toBe('label:~!@#$%^&*()');
      });
    });

    describe('processTokens', () => {
      describe('input does not contain any tokens', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer.processTokens('searchTerm');
        });

        it('returns input as searchToken', () => {
          expect(results.searchToken).toBe('searchTerm');
        });

        it('returns tokens as an empty array', () => {
          expect(results.tokens.length).toBe(0);
        });

        it('returns lastToken equal to searchToken', () => {
          expect(results.lastToken).toBe(results.searchToken);
        });
      });

      describe('input contains only tokens', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer
            .processTokens('author:@root label:~"Very Important" milestone:%v1.0 assignee:none');
        });

        it('returns searchToken as an empty string', () => {
          expect(results.searchToken).toBe('');
        });

        it('returns tokens array of size equal to the number of tokens in input', () => {
          expect(results.tokens.length).toBe(4);
        });

        it('returns tokens array that matches the tokens found in input', () => {
          expect(results.tokens[0].key).toBe('author');
          expect(results.tokens[0].value).toBe('@root');
          expect(results.tokens[0].wildcard).toBe(false);

          expect(results.tokens[1].key).toBe('label');
          expect(results.tokens[1].value).toBe('~Very Important');
          expect(results.tokens[1].wildcard).toBe(false);

          expect(results.tokens[2].key).toBe('milestone');
          expect(results.tokens[2].value).toBe('%v1.0');
          expect(results.tokens[2].wildcard).toBe(false);

          expect(results.tokens[3].key).toBe('assignee');
          expect(results.tokens[3].value).toBe('none');
          expect(results.tokens[3].wildcard).toBe(true);
        });

        it('returns lastToken equal to the last object in the tokens array', () => {
          expect(results.tokens[3]).toBe(results.lastToken);
        });
      });

      describe('input starts with search value and ends with tokens', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer
            .processTokens('searchTerm anotherSearchTerm milestone:none');
        });

        it('returns searchToken', () => {
          expect(results.searchToken).toBe('searchTerm anotherSearchTerm');
        });

        it('returns correct number of tokens', () => {
          expect(results.tokens.length).toBe(1);
        });

        it('returns correct tokens', () => {
          expect(results.tokens[0].key).toBe('milestone');
          expect(results.tokens[0].value).toBe('none');
          expect(results.tokens[0].wildcard).toBe(true);
        });

        it('returns lastToken', () => {
          expect(results.tokens[0]).toBe(results.lastToken);
        });
      });

      describe('input starts with token and ends with search value', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer
            .processTokens('assignee:@user searchTerm');
        });

        it('returns searchToken', () => {
          expect(results.searchToken).toBe('searchTerm');
        });

        it('returns correct number of tokens', () => {
          expect(results.tokens.length).toBe(1);
        });

        it('returns correct tokens', () => {
          expect(results.tokens[0].key).toBe('assignee');
          expect(results.tokens[0].value).toBe('@user');
          expect(results.tokens[0].wildcard).toBe(false);
        });

        it('returns lastToken as the searchTerm', () => {
          expect(results.lastToken).toBe(results.searchToken);
        });
      });

      describe('input contains search value wrapped between tokens', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer
            .processTokens('author:@root label:~"Won\'t fix" searchTerm anotherSearchTerm milestone:none');
        });

        it('returns searchToken', () => {
          expect(results.searchToken).toBe('searchTerm anotherSearchTerm');
        });

        it('returns correct number of tokens', () => {
          expect(results.tokens.length).toBe(3);
        });


        it('returns tokens array in the order it was processed', () => {
          expect(results.tokens[0].key).toBe('author');
          expect(results.tokens[0].value).toBe('@root');
          expect(results.tokens[0].wildcard).toBe(false);

          expect(results.tokens[1].key).toBe('label');
          expect(results.tokens[1].value).toBe('~Won\'t fix');
          expect(results.tokens[1].wildcard).toBe(false);

          expect(results.tokens[2].key).toBe('milestone');
          expect(results.tokens[2].value).toBe('none');
          expect(results.tokens[2].wildcard).toBe(true);
        });

        it('returns lastToken', () => {
          expect(results.tokens[2]).toBe(results.lastToken);
        });
      });

      describe('input search value is spaced in between tokens', () => {
        let results;
        beforeEach(() => {
          results = gl.FilteredSearchTokenizer
            .processTokens('author:@root searchTerm assignee:none anotherSearchTerm label:~Doing');
        });

        it('returns searchToken', () => {
          expect(results.searchToken).toBe('searchTerm anotherSearchTerm');
        });

        it('returns correct number of tokens', () => {
          expect(results.tokens.length).toBe(3);
        });

        it('returns tokens array in the order it was processed', () => {
          expect(results.tokens[0].key).toBe('author');
          expect(results.tokens[0].value).toBe('@root');
          expect(results.tokens[0].wildcard).toBe(false);

          expect(results.tokens[1].key).toBe('assignee');
          expect(results.tokens[1].value).toBe('none');
          expect(results.tokens[1].wildcard).toBe(true);

          expect(results.tokens[2].key).toBe('label');
          expect(results.tokens[2].value).toBe('~Doing');
          expect(results.tokens[2].wildcard).toBe(false);
        });

        it('returns lastToken', () => {
          expect(results.tokens[2]).toBe(results.lastToken);
        });
      });
    });
  });
})();
