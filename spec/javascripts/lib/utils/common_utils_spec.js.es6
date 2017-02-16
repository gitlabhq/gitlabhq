require('~/lib/utils/common_utils');

(() => {
  describe('common_utils', () => {
    describe('gl.utils.parseUrl', () => {
      it('returns an anchor tag with url', () => {
        expect(gl.utils.parseUrl('/some/absolute/url').pathname).toContain('some/absolute/url');
      });
      it('url is escaped', () => {
        // IE11 will return a relative pathname while other browsers will return a full pathname.
        // parseUrl uses an anchor element for parsing an url. With relative urls, the anchor
        // element will create an absolute url relative to the current execution context.
        // The JavaScript test suite is executed at '/' which will lead to an absolute url
        // starting with '/'.
        expect(gl.utils.parseUrl('" test="asf"').pathname).toContain('/%22%20test=%22asf%22');
      });
    });

    describe('gl.utils.parseUrlPathname', () => {
      beforeEach(() => {
        spyOn(gl.utils, 'parseUrl').and.callFake(url => ({
          pathname: url,
        }));
      });
      it('returns an absolute url when given an absolute url', () => {
        expect(gl.utils.parseUrlPathname('/some/absolute/url')).toEqual('/some/absolute/url');
      });
      it('returns an absolute url when given a relative url', () => {
        expect(gl.utils.parseUrlPathname('some/relative/url')).toEqual('/some/relative/url');
      });
    });

    describe('gl.utils.getUrlParamsArray', () => {
      it('should return params array', () => {
        expect(gl.utils.getUrlParamsArray() instanceof Array).toBe(true);
      });

      it('should remove the question mark from the search params', () => {
        const paramsArray = gl.utils.getUrlParamsArray();
        expect(paramsArray[0][0] !== '?').toBe(true);
      });
    });

    describe('gl.utils.handleLocationHash', () => {
      beforeEach(() => {
        spyOn(window.document, 'getElementById').and.callThrough();
      });

      function expectGetElementIdToHaveBeenCalledWith(elementId) {
        expect(window.document.getElementById).toHaveBeenCalledWith(elementId);
      }

      it('decodes hash parameter', () => {
        window.history.pushState({}, null, '#random-hash');
        gl.utils.handleLocationHash();

        expectGetElementIdToHaveBeenCalledWith('random-hash');
        expectGetElementIdToHaveBeenCalledWith('user-content-random-hash');
      });

      it('decodes cyrillic hash parameter', () => {
        window.history.pushState({}, null, '#definição');
        gl.utils.handleLocationHash();

        expectGetElementIdToHaveBeenCalledWith('definição');
        expectGetElementIdToHaveBeenCalledWith('user-content-definição');
      });

      it('decodes encoded cyrillic hash parameter', () => {
        window.history.pushState({}, null, '#defini%C3%A7%C3%A3o');
        gl.utils.handleLocationHash();

        expectGetElementIdToHaveBeenCalledWith('definição');
        expectGetElementIdToHaveBeenCalledWith('user-content-definição');
      });
    });

    describe('gl.utils.getParameterByName', () => {
      beforeEach(() => {
        window.history.pushState({}, null, '?scope=all&p=2');
      });

      it('should return valid parameter', () => {
        const value = gl.utils.getParameterByName('scope');
        expect(value).toBe('all');
      });

      it('should return invalid parameter', () => {
        const value = gl.utils.getParameterByName('fakeParameter');
        expect(value).toBe(null);
      });
    });

    describe('gl.utils.normalizedHeaders', () => {
      it('should upperCase all the header keys to keep them consistent', () => {
        const apiHeaders = {
          'X-Something-Workhorse': { workhorse: 'ok' },
          'x-something-nginx': { nginx: 'ok' },
        };

        const normalized = gl.utils.normalizeHeaders(apiHeaders);

        const WORKHORSE = 'X-SOMETHING-WORKHORSE';
        const NGINX = 'X-SOMETHING-NGINX';

        expect(normalized[WORKHORSE].workhorse).toBe('ok');
        expect(normalized[NGINX].nginx).toBe('ok');
      });
    });

    describe('gl.utils.parseIntPagination', () => {
      it('should parse to integers all string values and return pagination object', () => {
        const pagination = {
          'X-PER-PAGE': 10,
          'X-PAGE': 2,
          'X-TOTAL': 30,
          'X-TOTAL-PAGES': 3,
          'X-NEXT-PAGE': 3,
          'X-PREV-PAGE': 1,
        };

        const expectedPagination = {
          perPage: 10,
          page: 2,
          total: 30,
          totalPages: 3,
          nextPage: 3,
          previousPage: 1,
        };

        expect(gl.utils.parseIntPagination(pagination)).toEqual(expectedPagination);
      });
    });

    describe('gl.utils.isMetaClick', () => {
      it('should identify meta click on Windows/Linux', () => {
        const e = {
          metaKey: false,
          ctrlKey: true,
          which: 1,
        };

        expect(gl.utils.isMetaClick(e)).toBe(true);
      });

      it('should identify meta click on macOS', () => {
        const e = {
          metaKey: true,
          ctrlKey: false,
          which: 1,
        };

        expect(gl.utils.isMetaClick(e)).toBe(true);
      });

      it('should identify as meta click on middle-click or Mouse-wheel click', () => {
        const e = {
          metaKey: false,
          ctrlKey: false,
          which: 2,
        };

        expect(gl.utils.isMetaClick(e)).toBe(true);
      });
    });
  });
})();
