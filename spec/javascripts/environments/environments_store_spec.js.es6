const Store = require('~/environments/stores/environments_store');
const { environmentsList } = require('./mock_data');

(() => {
  describe('Store', () => {
    let store;

    beforeEach(() => {
      store = new Store();
    });

    it('should start with a blank state', () => {
      expect(store.state.environments.length).toBe(0);
      expect(store.state.stoppedCounter).toBe(0);
      expect(store.state.availableCounter).toBe(0);
    });

    it('should store environments', () => {
      store.storeEnvironments(environmentsList);
      expect(store.state.environments.length).toBe(environmentsList.length);
    });

    it('should store available count', () => {
      store.storeAvailableCount(2);
      expect(store.state.availableCounter).toBe(2);
    });

    it('should store stopped count', () => {
      store.storeStoppedCount(2);
      expect(store.state.stoppedCounter).toBe(2);
    });
  });
})();
