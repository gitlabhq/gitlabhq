//= require lib/utils/common_utils

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
        // The JavaScript test suite is executed at '/teaspoon' which will lead to an absolute
        // url starting with '/teaspoon'.
        expect(gl.utils.parseUrl('" test="asf"').pathname).toEqual('/teaspoon/%22%20test=%22asf%22');
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
        window.history.pushState({}, null, '#definição');
      });

      it('decodes hash parameter', () => {
        spyOn(window.document, 'getElementById').and.callThrough();
        gl.utils.handleLocationHash();
        expect(window.document.getElementById).toHaveBeenCalledWith('definição');
        expect(window.document.getElementById).toHaveBeenCalledWith('user-content-definição');
      });
    });

    describe('gl.utils.getParameterByName', () => {
      it('should return valid parameter', () => {
        const value = gl.utils.getParameterByName('reporter');
        expect(value).toBe('Console');
      });

      it('should return invalid parameter', () => {
        const value = gl.utils.getParameterByName('fakeParameter');
        expect(value).toBe(null);
      });
    });
  });
})();
