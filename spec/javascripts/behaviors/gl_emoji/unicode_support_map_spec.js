import getUnicodeSupportMap from '~/emoji/support/unicode_support_map';
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
        const getArgs = window.localStorage.getItem.calls.allArgs();
        const setArgs = window.localStorage.setItem.calls.allArgs();

        expect(getArgs[0][0]).toBe('gl-emoji-version');
        expect(getArgs[1][0]).toBe('gl-emoji-user-agent');

        expect(setArgs[0][0]).toBe('gl-emoji-version');
        expect(setArgs[0][1]).toBe('0.2.0');
        expect(setArgs[1][0]).toBe('gl-emoji-user-agent');
        expect(setArgs[1][1]).toBe(navigator.userAgent);
        expect(setArgs[2][0]).toBe('gl-emoji-unicode-support-map');
        expect(setArgs[2][1]).toBe(stringSupportMap);
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
