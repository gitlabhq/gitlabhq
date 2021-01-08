/**
 * This file should only contain browser specific specs.
 * If you need to add or update a spec, please see spec/frontend/lib/utils/*.js
 * https://gitlab.com/gitlab-org/gitlab/issues/194242#note_292137135
 * https://gitlab.com/groups/gitlab-org/-/epics/895#what-if-theres-a-karma-spec-which-is-simply-unmovable-to-jest-ie-it-is-dependent-on-a-running-browser-environment
 */

import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import * as commonUtils from '~/lib/utils/common_utils';

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
