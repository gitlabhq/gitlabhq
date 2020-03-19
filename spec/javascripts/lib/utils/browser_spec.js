/**
 * This file should only contain browser specific specs.
 * If you need to add or update a spec, please see spec/frontend/lib/utils/*.js
 * https://gitlab.com/gitlab-org/gitlab/issues/194242#note_292137135
 * https://gitlab.com/groups/gitlab-org/-/epics/895#what-if-theres-a-karma-spec-which-is-simply-unmovable-to-jest-ie-it-is-dependent-on-a-running-browser-environment
 */

import MockAdapter from 'axios-mock-adapter';
import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import axios from '~/lib/utils/axios_utils';
import * as commonUtils from '~/lib/utils/common_utils';
import { faviconDataUrl, overlayDataUrl, faviconWithOverlayDataUrl } from './mock_data';

const PIXEL_TOLERANCE = 0.2;

/**
 * Loads a data URL as the src of an
 * {@link https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/Image|Image}
 * and resolves to that Image once loaded.
 *
 * @param url
 * @returns {Promise}
 */
const urlToImage = url =>
  new Promise(resolve => {
    const img = new Image();
    img.onload = function() {
      resolve(img);
    };
    img.src = url;
  });

describe('common_utils browser specific specs', () => {
  describe('contentTop', () => {
    it('does not add height for fileTitle or compareVersionsHeader if screen is too small', () => {
      spyOn(breakpointInstance, 'isDesktop').and.returnValue(false);

      setFixtures(`
          <div class="diff-file file-title-flex-parent">
            blah blah blah
          </div>
          <div class="mr-version-controls">
            more blah blah blah
          </div>
        `);

      expect(commonUtils.contentTop()).toBe(0);
    });

    it('adds height for fileTitle and compareVersionsHeader screen is large enough', () => {
      spyOn(breakpointInstance, 'isDesktop').and.returnValue(true);

      setFixtures(`
          <div class="diff-file file-title-flex-parent">
            blah blah blah
          </div>
          <div class="mr-version-controls">
            more blah blah blah
          </div>
        `);

      expect(commonUtils.contentTop()).toBe(18);
    });
  });

  describe('createOverlayIcon', () => {
    it('should return the favicon with the overlay', done => {
      commonUtils
        .createOverlayIcon(faviconDataUrl, overlayDataUrl)
        .then(url => Promise.all([urlToImage(url), urlToImage(faviconWithOverlayDataUrl)]))
        .then(([actual, expected]) => {
          expect(actual).toImageDiffEqual(expected, PIXEL_TOLERANCE);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('setFaviconOverlay', () => {
    beforeEach(() => {
      const favicon = document.createElement('link');
      favicon.setAttribute('id', 'favicon');
      favicon.setAttribute('data-original-href', faviconDataUrl);
      document.body.appendChild(favicon);
    });

    afterEach(() => {
      document.body.removeChild(document.getElementById('favicon'));
    });

    it('should set page favicon to provided favicon overlay', done => {
      commonUtils
        .setFaviconOverlay(overlayDataUrl)
        .then(() => document.getElementById('favicon').getAttribute('href'))
        .then(url => Promise.all([urlToImage(url), urlToImage(faviconWithOverlayDataUrl)]))
        .then(([actual, expected]) => {
          expect(actual).toImageDiffEqual(expected, PIXEL_TOLERANCE);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('setCiStatusFavicon', () => {
    const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1/status.json`;
    let mock;

    beforeEach(() => {
      const favicon = document.createElement('link');
      favicon.setAttribute('id', 'favicon');
      favicon.setAttribute('href', 'null');
      favicon.setAttribute('data-original-href', faviconDataUrl);
      document.body.appendChild(favicon);
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      document.body.removeChild(document.getElementById('favicon'));
    });

    it('should reset favicon in case of error', done => {
      mock.onGet(BUILD_URL).replyOnce(500);

      commonUtils.setCiStatusFavicon(BUILD_URL).catch(() => {
        const favicon = document.getElementById('favicon');

        expect(favicon.getAttribute('href')).toEqual(faviconDataUrl);
        done();
      });
    });

    it('should set page favicon to CI status favicon based on provided status', done => {
      mock.onGet(BUILD_URL).reply(200, {
        favicon: overlayDataUrl,
      });

      commonUtils
        .setCiStatusFavicon(BUILD_URL)
        .then(() => document.getElementById('favicon').getAttribute('href'))
        .then(url => Promise.all([urlToImage(url), urlToImage(faviconWithOverlayDataUrl)]))
        .then(([actual, expected]) => {
          expect(actual).toImageDiffEqual(expected, PIXEL_TOLERANCE);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('isInViewport', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    afterEach(() => {
      document.body.removeChild(el);
    });

    it('returns true when provided `el` is in viewport', () => {
      el.setAttribute('style', `position: absolute; right: ${window.innerWidth + 0.2};`);
      document.body.appendChild(el);

      expect(commonUtils.isInViewport(el)).toBe(true);
    });

    it('returns false when provided `el` is not in viewport', () => {
      el.setAttribute('style', 'position: absolute; top: -1000px; left: -1000px;');
      document.body.appendChild(el);

      expect(commonUtils.isInViewport(el)).toBe(false);
    });
  });
});
