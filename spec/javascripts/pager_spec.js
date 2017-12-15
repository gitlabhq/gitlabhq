/* global fixture */

import * as utils from '~/lib/utils/url_utility';
import Pager from '~/pager';

describe('pager', () => {
  describe('init', () => {
    const originalHref = window.location.href;

    beforeEach(() => {
      setFixtures('<div class="content_list"></div><div class="loading"></div>');
      spyOn($, 'ajax');
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
      spyOn(utils, 'removeParams').and.returnValue(href);
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
      spyOn(utils, 'removeParams').and.returnValue(href);
      Pager.init();
      expect(utils.removeParams).toHaveBeenCalledWith(['limit', 'offset']);
      expect(Pager.url).toEqual(href);
    });
  });

  describe('getOld', () => {
    beforeEach(() => {
      setFixtures('<div class="content_list" data-href="/some_list"></div><div class="loading"></div>');
      Pager.init();
    });

    it('shows loader while loading next page', () => {
      spyOn(Pager.loading, 'show');
      Pager.getOld();
      expect(Pager.loading.show).toHaveBeenCalled();
    });

    it('hides loader on success', () => {
      spyOn($, 'ajax').and.callFake(options => options.success({}));
      spyOn(Pager.loading, 'hide');
      Pager.getOld();
      expect(Pager.loading.hide).toHaveBeenCalled();
    });

    it('hides loader on error', () => {
      spyOn($, 'ajax').and.callFake(options => options.error());
      spyOn(Pager.loading, 'hide');
      Pager.getOld();
      expect(Pager.loading.hide).toHaveBeenCalled();
    });

    it('sends request to url with offset and limit params', () => {
      spyOn($, 'ajax');
      Pager.offset = 100;
      Pager.limit = 20;
      Pager.getOld();
      const [{ data, url }] = $.ajax.calls.argsFor(0);
      expect(data).toBe('limit=20&offset=100');
      expect(url).toBe('/some_list');
    });
  });
});
