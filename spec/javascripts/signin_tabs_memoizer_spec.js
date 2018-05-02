import AccessorUtilities from '~/lib/utils/accessor';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';

(() => {
  describe('SigninTabsMemoizer', () => {
    const fixtureTemplate = 'static/signin_tabs.html.raw';
    const tabSelector = 'ul.new-session-tabs';
    const currentTabKey = 'current_signin_tab';
    let memo;

    function createMemoizer() {
      memo = new SigninTabsMemoizer({
        currentTabKey,
        tabSelector,
      });
      return memo;
    }

    preloadFixtures(fixtureTemplate);

    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').and.returnValue(true);
    });

    it('does nothing if no tab was previously selected', () => {
      createMemoizer();

      expect(document.querySelector(`${tabSelector} > li.active a`).getAttribute('href')).toEqual('#ldap');
    });

    it('shows last selected tab on boot', () => {
      createMemoizer().saveData('#ldap');
      const fakeTab = {
        click: () => {},
      };
      spyOn(document, 'querySelector').and.returnValue(fakeTab);
      spyOn(fakeTab, 'click');

      memo.bootstrap();

      // verify that triggers click on the last selected tab
      expect(document.querySelector).toHaveBeenCalledWith(`${tabSelector} a[href="#ldap"]`);
      expect(fakeTab.click).toHaveBeenCalled();
    });

    it('saves last selected tab on change', () => {
      createMemoizer();

      document.querySelector('a[href="#login-pane"]').click();

      expect(memo.readData()).toEqual('#login-pane');
    });

    it('overrides last selected tab with hash tag when given', () => {
      window.location.hash = '#ldap';
      createMemoizer();

      expect(memo.readData()).toEqual('#ldap');
    });

    describe('class constructor', () => {
      beforeEach(() => {
        memo = createMemoizer();
      });

      it('should set .isLocalStorageAvailable', () => {
        expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
        expect(memo.isLocalStorageAvailable).toBe(true);
      });
    });

    describe('saveData', () => {
      beforeEach(() => {
        memo = {
          currentTabKey,
        };

        spyOn(localStorage, 'setItem');
      });

      describe('if .isLocalStorageAvailable is `false`', () => {
        beforeEach(function () {
          memo.isLocalStorageAvailable = false;

          SigninTabsMemoizer.prototype.saveData.call(memo);
        });

        it('should not call .setItem', () => {
          expect(localStorage.setItem).not.toHaveBeenCalled();
        });
      });

      describe('if .isLocalStorageAvailable is `true`', () => {
        const value = 'value';

        beforeEach(function () {
          memo.isLocalStorageAvailable = true;

          SigninTabsMemoizer.prototype.saveData.call(memo, value);
        });

        it('should call .setItem', () => {
          expect(localStorage.setItem).toHaveBeenCalledWith(currentTabKey, value);
        });
      });
    });

    describe('readData', () => {
      const itemValue = 'itemValue';
      let readData;

      beforeEach(() => {
        memo = {
          currentTabKey,
        };

        spyOn(localStorage, 'getItem').and.returnValue(itemValue);
      });

      describe('if .isLocalStorageAvailable is `false`', () => {
        beforeEach(function () {
          memo.isLocalStorageAvailable = false;

          readData = SigninTabsMemoizer.prototype.readData.call(memo);
        });

        it('should not call .getItem and should return `null`', () => {
          expect(localStorage.getItem).not.toHaveBeenCalled();
          expect(readData).toBe(null);
        });
      });

      describe('if .isLocalStorageAvailable is `true`', () => {
        beforeEach(function () {
          memo.isLocalStorageAvailable = true;

          readData = SigninTabsMemoizer.prototype.readData.call(memo);
        });

        it('should call .getItem and return the localStorage value', () => {
          expect(window.localStorage.getItem).toHaveBeenCalledWith(currentTabKey);
          expect(readData).toBe(itemValue);
        });
      });
    });
  });
})();
