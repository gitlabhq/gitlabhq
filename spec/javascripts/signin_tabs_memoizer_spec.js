require('~/signin_tabs_memoizer');

((global) => {
  describe('SigninTabsMemoizer', () => {
    const fixtureTemplate = 'static/signin_tabs.html.raw';
    const tabSelector = 'ul.nav-tabs';
    const currentTabKey = 'current_signin_tab';
    let memo;

    function createMemoizer() {
      memo = new global.ActiveTabMemoizer({
        currentTabKey,
        tabSelector,
      });
      return memo;
    }

    preloadFixtures(fixtureTemplate);

    beforeEach(() => {
      loadFixtures(fixtureTemplate);
    });

    it('does nothing if no tab was previously selected', () => {
      createMemoizer();

      expect(document.querySelector('li a.active').getAttribute('id')).toEqual('standard');
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

      document.getElementById('standard').click();

      expect(memo.readData()).toEqual('#standard');
    });
  });
})(window);
