import * as getters from '~/ide/stores/modules/pane/getters';
import state from '~/ide/stores/modules/pane/state';

describe('IDE pane module getters', () => {
  const TEST_VIEW = 'test-view';
  const TEST_KEEP_ALIVE_VIEWS = {
    [TEST_VIEW]: true,
  };

  describe('isActiveView', () => {
    it('returns true if given view matches currentView', () => {
      const result = getters.isActiveView({ currentView: 'A' })('A');

      expect(result).toBe(true);
    });

    it('returns false if given view does not match currentView', () => {
      const result = getters.isActiveView({ currentView: 'A' })('B');

      expect(result).toBe(false);
    });
  });

  describe('isAliveView', () => {
    it('returns true if given view is in keepAliveViews', () => {
      const result = getters.isAliveView({ keepAliveViews: TEST_KEEP_ALIVE_VIEWS }, {})(TEST_VIEW);

      expect(result).toBe(true);
    });

    it('returns true if given view is active view and open', () => {
      const result = getters.isAliveView(
        { ...state(), isOpen: true },
        { isActiveView: () => true },
      )(TEST_VIEW);

      expect(result).toBe(true);
    });

    it('returns false if given view is active view and closed', () => {
      const result = getters.isAliveView(state(), { isActiveView: () => true })(TEST_VIEW);

      expect(result).toBe(false);
    });

    it('returns false if given view is not activeView', () => {
      const result = getters.isAliveView(
        { ...state(), isOpen: true },
        { isActiveView: () => false },
      )(TEST_VIEW);

      expect(result).toBe(false);
    });
  });
});
