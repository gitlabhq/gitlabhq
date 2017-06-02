import { getUnicodeSupportMap } from '~/behaviors/gl_emoji/unicode_support_map';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Unicode Support Map', () => {
  describe('getUnicodeSupportMap', () => {
    const stringSupportMap = 'stringSupportMap';

    beforeEach(() => {
      spyOn(AccessorUtilities, 'isLocalStorageAccessSafe');
      spyOn(window.localStorage, 'getItem');
      spyOn(window.localStorage, 'setItem');
      spyOn(JSON, 'parse');
      spyOn(JSON, 'stringify').and.returnValue(stringSupportMap);
    });

    describe('if isLocalStorageAvailable is `true`', function () {
      beforeEach(() => {
        AccessorUtilities.isLocalStorageAccessSafe.and.returnValue(true);

        getUnicodeSupportMap();
      });

      it('should call .getItem and .setItem', () => {
        const allArgs = window.localStorage.setItem.calls.allArgs();

        expect(window.localStorage.getItem).toHaveBeenCalledWith('gl-emoji-user-agent');
        expect(allArgs[0][0]).toBe('gl-emoji-user-agent');
        expect(allArgs[0][1]).toBe(navigator.userAgent);
        expect(allArgs[1][0]).toBe('gl-emoji-unicode-support-map');
        expect(allArgs[1][1]).toBe(stringSupportMap);
      });
    });

    describe('if isLocalStorageAvailable is `false`', function () {
      beforeEach(() => {
        AccessorUtilities.isLocalStorageAccessSafe.and.returnValue(false);

        getUnicodeSupportMap();
      });

      it('should not call .getItem or .setItem', () => {
        expect(window.localStorage.getItem.calls.count()).toBe(1);
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });
  });
});
