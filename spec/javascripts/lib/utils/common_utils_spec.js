/* eslint-disable promise/catch-or-return */
import axios from '~/lib/utils/axios_utils';
import * as commonUtils from '~/lib/utils/common_utils';
import MockAdapter from 'axios-mock-adapter';

describe('common_utils', () => {
  describe('parseUrl', () => {
    it('returns an anchor tag with url', () => {
      expect(commonUtils.parseUrl('/some/absolute/url').pathname).toContain('some/absolute/url');
    });
    it('url is escaped', () => {
      // IE11 will return a relative pathname while other browsers will return a full pathname.
      // parseUrl uses an anchor element for parsing an url. With relative urls, the anchor
      // element will create an absolute url relative to the current execution context.
      // The JavaScript test suite is executed at '/' which will lead to an absolute url
      // starting with '/'.
      expect(commonUtils.parseUrl('" test="asf"').pathname).toContain('/%22%20test=%22asf%22');
    });
  });

  describe('parseUrlPathname', () => {
    it('returns an absolute url when given an absolute url', () => {
      expect(commonUtils.parseUrlPathname('/some/absolute/url')).toEqual('/some/absolute/url');
    });

    it('returns an absolute url when given a relative url', () => {
      expect(commonUtils.parseUrlPathname('some/relative/url')).toEqual('/some/relative/url');
    });
  });

  describe('getUrlParamsArray', () => {
    it('should return params array', () => {
      expect(commonUtils.getUrlParamsArray() instanceof Array).toBe(true);
    });

    it('should remove the question mark from the search params', () => {
      const paramsArray = commonUtils.getUrlParamsArray();
      expect(paramsArray[0][0] !== '?').toBe(true);
    });

    it('should decode params', () => {
      history.pushState('', '', '?label_name%5B%5D=test');

      expect(
        commonUtils.getUrlParamsArray()[0],
      ).toBe('label_name[]=test');

      history.pushState('', '', '?');
    });
  });

  describe('handleLocationHash', () => {
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
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('random-hash');
      expectGetElementIdToHaveBeenCalledWith('user-content-random-hash');
    });

    it('decodes cyrillic hash parameter', () => {
      window.history.pushState({}, null, '#definição');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('definição');
      expectGetElementIdToHaveBeenCalledWith('user-content-definição');
    });

    it('decodes encoded cyrillic hash parameter', () => {
      window.history.pushState({}, null, '#defini%C3%A7%C3%A3o');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('definição');
      expectGetElementIdToHaveBeenCalledWith('user-content-definição');
    });

    it('scrolls element into view', () => {
      document.body.innerHTML += `
        <div id="parent">
          <div style="height: 2000px;"></div>
          <div id="test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('test');
      expect(window.scrollY).toBe(document.getElementById('test').offsetTop);

      document.getElementById('parent').remove();
    });

    it('scrolls user content element into view', () => {
      document.body.innerHTML += `
        <div id="parent">
          <div style="height: 2000px;"></div>
          <div id="user-content-test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');
      expect(window.scrollY).toBe(document.getElementById('user-content-test').offsetTop);

      document.getElementById('parent').remove();
    });

    it('scrolls to element with offset from navbar', () => {
      spyOn(window, 'scrollBy').and.callThrough();
      document.body.innerHTML += `
        <div id="parent">
          <div class="navbar-gitlab" style="position: fixed; top: 0; height: 50px;"></div>
          <div style="height: 2000px; margin-top: 50px;"></div>
          <div id="user-content-test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');
      expect(window.scrollY).toBe(document.getElementById('user-content-test').offsetTop - 50);
      expect(window.scrollBy).toHaveBeenCalledWith(0, -50);

      document.getElementById('parent').remove();
    });
  });

  describe('historyPushState', () => {
    afterEach(() => {
      window.history.replaceState({}, null, null);
    });

    it('should call pushState with the correct path', () => {
      spyOn(window.history, 'pushState');

      commonUtils.historyPushState('newpath?page=2');

      expect(window.history.pushState).toHaveBeenCalled();
      expect(window.history.pushState.calls.allArgs()[0][2]).toContain('newpath?page=2');
    });
  });

  describe('parseQueryStringIntoObject', () => {
    it('should return object with query parameters', () => {
      expect(commonUtils.parseQueryStringIntoObject('scope=all&page=2')).toEqual({ scope: 'all', page: '2' });
      expect(commonUtils.parseQueryStringIntoObject('scope=all')).toEqual({ scope: 'all' });
      expect(commonUtils.parseQueryStringIntoObject()).toEqual({});
    });
  });

  describe('objectToQueryString', () => {
    it('returns empty string when `param` is undefined, null or empty string', () => {
      expect(commonUtils.objectToQueryString()).toBe('');
      expect(commonUtils.objectToQueryString('')).toBe('');
    });

    it('returns query string with values of `params`', () => {
      const singleQueryParams = { foo: true };
      const multipleQueryParams = { foo: true, bar: true };

      expect(commonUtils.objectToQueryString(singleQueryParams)).toBe('foo=true');
      expect(commonUtils.objectToQueryString(multipleQueryParams)).toBe('foo=true&bar=true');
    });
  });

  describe('buildUrlWithCurrentLocation', () => {
    it('should build an url with current location and given parameters', () => {
      expect(commonUtils.buildUrlWithCurrentLocation()).toEqual(window.location.pathname);
      expect(commonUtils.buildUrlWithCurrentLocation('?page=2')).toEqual(`${window.location.pathname}?page=2`);
    });
  });

  describe('getParameterByName', () => {
    beforeEach(() => {
      window.history.pushState({}, null, '?scope=all&p=2');
    });

    afterEach(() => {
      window.history.replaceState({}, null, null);
    });

    it('should return valid parameter', () => {
      const value = commonUtils.getParameterByName('scope');
      expect(commonUtils.getParameterByName('p')).toEqual('2');
      expect(value).toBe('all');
    });

    it('should return invalid parameter', () => {
      const value = commonUtils.getParameterByName('fakeParameter');
      expect(value).toBe(null);
    });

    it('should return valid paramentes if URL is provided', () => {
      let value = commonUtils.getParameterByName('foo', 'http://cocteau.twins/?foo=bar');
      expect(value).toBe('bar');

      value = commonUtils.getParameterByName('manan', 'http://cocteau.twins/?foo=bar&manan=canchu');
      expect(value).toBe('canchu');
    });
  });

  describe('normalizedHeaders', () => {
    it('should upperCase all the header keys to keep them consistent', () => {
      const apiHeaders = {
        'X-Something-Workhorse': { workhorse: 'ok' },
        'x-something-nginx': { nginx: 'ok' },
      };

      const normalized = commonUtils.normalizeHeaders(apiHeaders);

      const WORKHORSE = 'X-SOMETHING-WORKHORSE';
      const NGINX = 'X-SOMETHING-NGINX';

      expect(normalized[WORKHORSE].workhorse).toBe('ok');
      expect(normalized[NGINX].nginx).toBe('ok');
    });
  });

  describe('normalizeCRLFHeaders', () => {
    beforeEach(function () {
      this.CLRFHeaders = 'a-header: a-value\nAnother-Header: ANOTHER-VALUE\nLaSt-HeAdEr: last-VALUE';
      spyOn(String.prototype, 'split').and.callThrough();
      this.normalizeCRLFHeaders = commonUtils.normalizeCRLFHeaders(this.CLRFHeaders);
    });

    it('should split by newline', function () {
      expect(String.prototype.split).toHaveBeenCalledWith('\n');
    });

    it('should split by colon+space for each header', function () {
      expect(String.prototype.split.calls.allArgs().filter(args => args[0] === ': ').length).toBe(3);
    });

    it('should return a normalized headers object', function () {
      expect(this.normalizeCRLFHeaders).toEqual({
        'A-HEADER': 'a-value',
        'ANOTHER-HEADER': 'ANOTHER-VALUE',
        'LAST-HEADER': 'last-VALUE',
      });
    });
  });

  describe('parseIntPagination', () => {
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

      expect(commonUtils.parseIntPagination(pagination)).toEqual(expectedPagination);
    });
  });

  describe('isMetaClick', () => {
    it('should identify meta click on Windows/Linux', () => {
      const e = {
        metaKey: false,
        ctrlKey: true,
        which: 1,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });

    it('should identify meta click on macOS', () => {
      const e = {
        metaKey: true,
        ctrlKey: false,
        which: 1,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });

    it('should identify as meta click on middle-click or Mouse-wheel click', () => {
      const e = {
        metaKey: false,
        ctrlKey: false,
        which: 2,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });
  });

  describe('convertPermissionToBoolean', () => {
    it('should convert a boolean in a string to a boolean', () => {
      expect(commonUtils.convertPermissionToBoolean('true')).toEqual(true);
      expect(commonUtils.convertPermissionToBoolean('false')).toEqual(false);
    });
  });

  describe('backOff', () => {
    beforeEach(() => {
      // shortcut our timeouts otherwise these tests will take a long time to finish
      const origSetTimeout = window.setTimeout;
      spyOn(window, 'setTimeout').and.callFake(cb => origSetTimeout(cb, 0));
    });

    it('solves the promise from the callback', (done) => {
      const expectedResponseValue = 'Success!';
      commonUtils.backOff((next, stop) => (
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
      commonUtils.backOff((next, stop) => {
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
      commonUtils.backOff((next, stop) => (
        Promise.resolve(expectedResponseValue)
          .then((resp) => {
            if (numberOfCalls < 3) {
              numberOfCalls += 1;
              next();
            } else {
              stop(resp);
            }
          })
      )).then((respBackoff) => {
        const timeouts = window.setTimeout.calls.allArgs().map(([, timeout]) => timeout);
        expect(timeouts).toEqual([2000, 4000]);
        expect(respBackoff).toBe(expectedResponseValue);
        done();
      });
    });

    it('rejects the backOff promise after timing out', (done) => {
      commonUtils.backOff(next => next(), 64000)
        .catch((errBackoffResp) => {
          const timeouts = window.setTimeout.calls.allArgs().map(([, timeout]) => timeout);
          expect(timeouts).toEqual([2000, 4000, 8000, 16000, 32000, 32000]);
          expect(errBackoffResp instanceof Error).toBe(true);
          expect(errBackoffResp.message).toBe('BACKOFF_TIMEOUT');
          done();
        });
    });
  });

  describe('setFavicon', () => {
    beforeEach(() => {
      const favicon = document.createElement('link');
      favicon.setAttribute('id', 'favicon');
      favicon.setAttribute('href', 'default/favicon');
      document.body.appendChild(favicon);
    });

    afterEach(() => {
      document.body.removeChild(document.getElementById('favicon'));
    });
    it('should set page favicon to provided favicon', () => {
      const faviconPath = '//custom_favicon';
      commonUtils.setFavicon(faviconPath);

      expect(document.getElementById('favicon').getAttribute('href')).toEqual(faviconPath);
    });
  });

  describe('resetFavicon', () => {
    beforeEach(() => {
      const favicon = document.createElement('link');
      favicon.setAttribute('id', 'favicon');
      favicon.setAttribute('href', 'default/favicon');
      document.body.appendChild(favicon);
    });

    afterEach(() => {
      document.body.removeChild(document.getElementById('favicon'));
    });

    it('should reset page favicon to tanuki', () => {
      commonUtils.resetFavicon();
      expect(document.getElementById('favicon').getAttribute('href')).toEqual('default/favicon');
    });
  });

  describe('setCiStatusFavicon', () => {
    const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1/status.json`;
    let mock;

    beforeEach(() => {
      const favicon = document.createElement('link');
      favicon.setAttribute('id', 'favicon');
      document.body.appendChild(favicon);
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      document.body.removeChild(document.getElementById('favicon'));
    });

    it('should reset favicon in case of error', (done) => {
      mock.onGet(BUILD_URL).networkError();

      commonUtils.setCiStatusFavicon(BUILD_URL)
        .then(() => {
          const favicon = document.getElementById('favicon');
          expect(favicon.getAttribute('href')).toEqual('null');
          done();
        })
        // Error is already caught in catch() block of setCiStatusFavicon,
        // It won't throw another error for us to catch
        .catch(done.fail);
    });

    it('should set page favicon to CI status favicon based on provided status', (done) => {
      const FAVICON_PATH = '//icon_status_success';

      mock.onGet(BUILD_URL).reply(200, {
        favicon: FAVICON_PATH,
      });

      commonUtils.setCiStatusFavicon(BUILD_URL)
        .then(() => {
          const favicon = document.getElementById('favicon');
          expect(favicon.getAttribute('href')).toEqual(FAVICON_PATH);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('spriteIcon', () => {
    let beforeGon;

    beforeEach(() => {
      window.gon = window.gon || {};
      beforeGon = Object.assign({}, window.gon);
      window.gon.sprite_icons = 'icons.svg';
    });

    afterEach(() => {
      window.gon = beforeGon;
    });

    it('should return the svg for a linked icon', () => {
      expect(commonUtils.spriteIcon('test')).toEqual('<svg ><use xlink:href="icons.svg#test" /></svg>');
    });

    it('should set svg className when passed', () => {
      expect(commonUtils.spriteIcon('test', 'fa fa-test')).toEqual('<svg class="fa fa-test"><use xlink:href="icons.svg#test" /></svg>');
    });
  });

  describe('convertObjectPropsToCamelCase', () => {
    it('returns new object with camelCase property names by converting object with snake_case names', () => {
      const snakeRegEx = /(_\w)/g;
      const mockObj = {
        id: 1,
        group_name: 'GitLab.org',
        absolute_web_url: 'https://gitlab.com/gitlab-org/',
      };
      const mappings = {
        id: 'id',
        groupName: 'group_name',
        absoluteWebUrl: 'absolute_web_url',
      };

      const convertedObj = commonUtils.convertObjectPropsToCamelCase(mockObj);

      Object.keys(convertedObj).forEach((prop) => {
        expect(snakeRegEx.test(prop)).toBeFalsy();
        expect(convertedObj[prop]).toBe(mockObj[mappings[prop]]);
      });
    });

    it('return empty object if method is called with null or undefined', () => {
      expect(Object.keys(commonUtils.convertObjectPropsToCamelCase(null)).length).toBe(0);
      expect(Object.keys(commonUtils.convertObjectPropsToCamelCase()).length).toBe(0);
      expect(Object.keys(commonUtils.convertObjectPropsToCamelCase({})).length).toBe(0);
    });

    it('does not deep-convert by default', () => {
      const obj = {
        snake_key: {
          child_snake_key: 'value',
        },
      };

      expect(
        commonUtils.convertObjectPropsToCamelCase(obj),
      ).toEqual({
        snakeKey: {
          child_snake_key: 'value',
        },
      });
    });

    describe('deep: true', () => {
      it('converts object with child objects', () => {
        const obj = {
          snake_key: {
            child_snake_key: 'value',
          },
        };

        expect(
          commonUtils.convertObjectPropsToCamelCase(obj, { deep: true }),
        ).toEqual({
          snakeKey: {
            childSnakeKey: 'value',
          },
        });
      });

      it('converts array with child objects', () => {
        const arr = [
          {
            child_snake_key: 'value',
          },
        ];

        expect(
          commonUtils.convertObjectPropsToCamelCase(arr, { deep: true }),
        ).toEqual([
          {
            childSnakeKey: 'value',
          },
        ]);
      });

      it('converts array with child arrays', () => {
        const arr = [
          [
            {
              child_snake_key: 'value',
            },
          ],
        ];

        expect(
          commonUtils.convertObjectPropsToCamelCase(arr, { deep: true }),
        ).toEqual([
          [
            {
              childSnakeKey: 'value',
            },
          ],
        ]);
      });
    });
  });
});
