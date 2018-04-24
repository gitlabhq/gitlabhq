import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Pager from '~/pager';

describe('pager', () => {
  describe('init', () => {
    const originalHref = window.location.href;

    beforeEach(() => {
      setFixtures('<div class="content_list"></div><div class="loading"></div>');
    });

    afterEach(() => {
      window.history.replaceState({}, null, originalHref);
    });

    it('should use data-href attribute from list element', () => {
      const href = `${gl.TEST_HOST}/some_list.json`;
      setFixtures(`<div class="content_list" data-href="${href}"></div>`);
      Pager.init();
      expect(Pager.url).toBe(href);
    });

    it('should use current url if data-href attribute not provided', () => {
      const href = `${gl.TEST_HOST}/some_list`;
      spyOnDependency(Pager, 'removeParams').and.returnValue(href);
      Pager.init();
      expect(Pager.url).toBe(href);
    });

    it('should get initial offset from query parameter', () => {
      window.history.replaceState({}, null, '?offset=100');
      Pager.init();
      expect(Pager.offset).toBe(100);
    });

    it('keeps extra query parameters from url', () => {
      window.history.replaceState({}, null, '?filter=test&offset=100');
      const href = `${gl.TEST_HOST}/some_list?filter=test`;
      const removeParams = spyOnDependency(Pager, 'removeParams').and.returnValue(href);
      Pager.init();
      expect(removeParams).toHaveBeenCalledWith(['limit', 'offset']);
      expect(Pager.url).toEqual(href);
    });
  });

  describe('getOld', () => {
    const urlRegex = /(.*)some_list(.*)$/;
    let mock;

    function mockSuccess() {
      mock.onGet(urlRegex).reply(200, {
        count: 0,
        html: '',
      });
    }

    function mockError() {
      mock.onGet(urlRegex).networkError();
    }

    beforeEach(() => {
      setFixtures('<div class="content_list" data-href="/some_list"></div><div class="loading"></div>');
      spyOn(axios, 'get').and.callThrough();

      mock = new MockAdapter(axios);

      Pager.init();
    });

    afterEach(() => {
      mock.restore();
    });

    it('shows loader while loading next page', (done) => {
      mockSuccess();

      spyOn(Pager.loading, 'show');
      Pager.getOld();

      setTimeout(() => {
        expect(Pager.loading.show).toHaveBeenCalled();

        done();
      });
    });

    it('hides loader on success', (done) => {
      mockSuccess();

      spyOn(Pager.loading, 'hide');
      Pager.getOld();

      setTimeout(() => {
        expect(Pager.loading.hide).toHaveBeenCalled();

        done();
      });
    });

    it('hides loader on error', (done) => {
      mockError();

      spyOn(Pager.loading, 'hide');
      Pager.getOld();

      setTimeout(() => {
        expect(Pager.loading.hide).toHaveBeenCalled();

        done();
      });
    });

    it('sends request to url with offset and limit params', (done) => {
      Pager.offset = 100;
      Pager.limit = 20;
      Pager.getOld();

      setTimeout(() => {
        const [url, params] = axios.get.calls.argsFor(0);

        expect(params).toEqual({
          params: {
            limit: 20,
            offset: 100,
          },
        });
        expect(url).toBe('/some_list');

        done();
      });
    });
  });
});
