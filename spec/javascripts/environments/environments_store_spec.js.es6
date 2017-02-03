/* global environmentsList */

require('~/environments/stores/environments_store');
require('./mock_data');

(() => {
  describe('Store', () => {
    beforeEach(() => {
      gl.environmentsList.EnvironmentsStore.create();
    });

    it('should start with a blank state', () => {
      expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.stoppedCounter).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.availableCounter).toBe(0);
    });

    describe('store environments', () => {
      beforeEach(() => {
        gl.environmentsList.EnvironmentsStore.storeEnvironments(environmentsList);
      });

      it('should store environments', () => {
        expect(
          gl.environmentsList.EnvironmentsStore.state.environments.length
        ).toBe(environmentsList.length);
      });
    });
  });
})();
