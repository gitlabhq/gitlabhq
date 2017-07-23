/* eslint-disable promise/catch-or-return */

import '~/lib/utils/common_utils';

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

      it('should decode params', () => {
        history.pushState('', '', '?label_name%5B%5D=test');

        expect(
          gl.utils.getUrlParamsArray()[0],
        ).toBe('label_name[]=test');

        history.pushState('', '', '?');
      });
    });

    describe('gl.utils.handleLocationHash', () => {
      beforeEach(() => {
        spyOn(window.document, 'getElementById').and.callThrough();
      });

      afterEach(() => {
        window.history.pushState({}, null, '');
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

    describe('gl.utils.setParamInURL', () => {
      afterEach(() => {
        window.history.pushState({}, null, '');
      });

      it('should return the parameter', () => {
        window.history.replaceState({}, null, '');

        expect(gl.utils.setParamInURL('page', 156)).toBe('?page=156');
        expect(gl.utils.setParamInURL('page', '156')).toBe('?page=156');
      });

      it('should update the existing parameter when its a number', () => {
        window.history.pushState({}, null, '?page=15');

        expect(gl.utils.setParamInURL('page', 16)).toBe('?page=16');
        expect(gl.utils.setParamInURL('page', '16')).toBe('?page=16');
        expect(gl.utils.setParamInURL('page', true)).toBe('?page=true');
      });

      it('should update the existing parameter when its a string', () => {
        window.history.pushState({}, null, '?scope=all');

        expect(gl.utils.setParamInURL('scope', 'finished')).toBe('?scope=finished');
      });

      it('should update the existing parameter when more than one parameter exists', () => {
        window.history.pushState({}, null, '?scope=all&page=15');

        expect(gl.utils.setParamInURL('scope', 'finished')).toBe('?scope=finished&page=15');
      });

      it('should add a new parameter to the end of the existing ones', () => {
        window.history.pushState({}, null, '?scope=all');

        expect(gl.utils.setParamInURL('page', 16)).toBe('?scope=all&page=16');
        expect(gl.utils.setParamInURL('page', '16')).toBe('?scope=all&page=16');
        expect(gl.utils.setParamInURL('page', true)).toBe('?scope=all&page=true');
      });
    });

    describe('gl.utils.getParameterByName', () => {
      beforeEach(() => {
        window.history.pushState({}, null, '?scope=all&p=2');
      });

      afterEach(() => {
        window.history.replaceState({}, null, null);
      });

      it('should return valid parameter', () => {
        const value = gl.utils.getParameterByName('scope');
        expect(gl.utils.getParameterByName('p')).toEqual('2');
        expect(value).toBe('all');
      });

      it('should return invalid parameter', () => {
        const value = gl.utils.getParameterByName('fakeParameter');
        expect(value).toBe(null);
      });

      it('should return valid paramentes if URL is provided', () => {
        let value = gl.utils.getParameterByName('foo', 'http://cocteau.twins/?foo=bar');
        expect(value).toBe('bar');

        value = gl.utils.getParameterByName('manan', 'http://cocteau.twins/?foo=bar&manan=canchu');
        expect(value).toBe('canchu');
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

    describe('gl.utils.normalizeCRLFHeaders', () => {
      beforeEach(function () {
        this.CLRFHeaders = 'a-header: a-value\nAnother-Header: ANOTHER-VALUE\nLaSt-HeAdEr: last-VALUE';

        spyOn(String.prototype, 'split').and.callThrough();
        spyOn(gl.utils, 'normalizeHeaders').and.callThrough();

        this.normalizeCRLFHeaders = gl.utils.normalizeCRLFHeaders(this.CLRFHeaders);
      });

      it('should split by newline', function () {
        expect(String.prototype.split).toHaveBeenCalledWith('\n');
      });

      it('should split by colon+space for each header', function () {
        expect(String.prototype.split.calls.allArgs().filter(args => args[0] === ': ').length).toBe(3);
      });

      it('should call gl.utils.normalizeHeaders with a parsed headers object', function () {
        expect(gl.utils.normalizeHeaders).toHaveBeenCalledWith(jasmine.any(Object));
      });

      it('should return a normalized headers object', function () {
        expect(this.normalizeCRLFHeaders).toEqual({
          'A-HEADER': 'a-value',
          'ANOTHER-HEADER': 'ANOTHER-VALUE',
          'LAST-HEADER': 'last-VALUE',
        });
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

    describe('gl.utils.backOff', () => {
      it('solves the promise from the callback', (done) => {
        const expectedResponseValue = 'Success!';
        gl.utils.backOff((next, stop) => (
          new Promise((resolve) => {
            resolve(expectedResponseValue);
          }).then((resp) => {
            stop(resp);
          })
        )).then((respBackoff) => {
          expect(respBackoff).toBe(expectedResponseValue);
          done();
        });
      });

      it('catches the rejected promise from the callback ', (done) => {
        const errorMessage = 'Mistakes were made!';
        gl.utils.backOff((next, stop) => {
          new Promise((resolve, reject) => {
            reject(new Error(errorMessage));
          }).then((resp) => {
            stop(resp);
          }).catch(err => stop(err));
        }).catch((errBackoffResp) => {
          expect(errBackoffResp instanceof Error).toBe(true);
          expect(errBackoffResp.message).toBe(errorMessage);
          done();
        });
      });

      it('solves the promise correctly after retrying a third time', (done) => {
        let numberOfCalls = 1;
        const expectedResponseValue = 'Success!';
        gl.utils.backOff((next, stop) => (
          new Promise((resolve) => {
            resolve(expectedResponseValue);
          }).then((resp) => {
            if (numberOfCalls < 3) {
              numberOfCalls += 1;
              next();
            } else {
              stop(resp);
            }
          })
        )).then((respBackoff) => {
          expect(respBackoff).toBe(expectedResponseValue);
          expect(numberOfCalls).toBe(3);
          done();
        });
      }, 10000);

      it('rejects the backOff promise after timing out', (done) => {
        const expectedResponseValue = 'Success!';
        gl.utils.backOff(next => (
          new Promise((resolve) => {
            resolve(expectedResponseValue);
          }).then(() => {
            setTimeout(next(), 5000); // it will time out
          })
        ), 3000).catch((errBackoffResp) => {
          expect(errBackoffResp instanceof Error).toBe(true);
          expect(errBackoffResp.message).toBe('BACKOFF_TIMEOUT');
          done();
        });
      }, 10000);
    });

    describe('gl.utils.setFavicon', () => {
      it('should set page favicon to provided favicon', () => {
        const faviconPath = '//custom_favicon';
        const fakeLink = {
          setAttribute() {},
        };

        spyOn(window.document, 'getElementById').and.callFake(() => fakeLink);
        spyOn(fakeLink, 'setAttribute').and.callFake((attr, val) => {
          expect(attr).toEqual('href');
          expect(val.indexOf(faviconPath) > -1).toBe(true);
        });
        gl.utils.setFavicon(faviconPath);
      });
    });

    describe('gl.utils.resetFavicon', () => {
      it('should reset page favicon to tanuki', () => {
        const fakeLink = {
          setAttribute() {},
        };

        spyOn(window.document, 'getElementById').and.callFake(() => fakeLink);
        spyOn(fakeLink, 'setAttribute').and.callFake((attr, val) => {
          expect(attr).toEqual('href');
          expect(val).toMatch(/favicon/);
        });
        gl.utils.resetFavicon();
      });
    });

    describe('gl.utils.setCiStatusFavicon', () => {
      it('should set page favicon to CI status favicon based on provided status', () => {
        const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1/status.json`;
        const FAVICON_PATH = '//icon_status_success';
        const spySetFavicon = spyOn(gl.utils, 'setFavicon').and.stub();
        const spyResetFavicon = spyOn(gl.utils, 'resetFavicon').and.stub();
        spyOn($, 'ajax').and.callFake(function (options) {
          options.success({ favicon: FAVICON_PATH });
          expect(spySetFavicon).toHaveBeenCalledWith(FAVICON_PATH);
          options.success();
          expect(spyResetFavicon).toHaveBeenCalled();
          options.error();
          expect(spyResetFavicon).toHaveBeenCalled();
        });

        gl.utils.setCiStatusFavicon(BUILD_URL);
      });
    });

    describe('gl.utils.ajaxPost', () => {
      it('should perform `$.ajax` call and do `POST` request', () => {
        const requestURL = '/some/random/api';
        const data = { keyname: 'value' };
        const ajaxSpy = spyOn($, 'ajax').and.callFake(() => {});

        gl.utils.ajaxPost(requestURL, data);
        expect(ajaxSpy.calls.allArgs()[0][0].type).toEqual('POST');
      });
    });
  });
})();
