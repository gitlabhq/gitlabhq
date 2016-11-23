/* global environmentsList */

//= require vue
//= require environments/stores/environments_store
//= require ./mock_data

(() => {
  beforeEach(() => {
    gl.environmentsList.EnvironmentsStore.create();
  });

  describe('Store', () => {
    it('should start with a blank state', () => {
      expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.stoppedCounter).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.availableCounter).toBe(0);
    });

    describe('store environments', () => {
      beforeEach(() => {
        gl.environmentsList.EnvironmentsStore.storeEnvironments(environmentsList);
      });

      it('should count stopped environments and save the count in the state', () => {
        expect(gl.environmentsList.EnvironmentsStore.state.stoppedCounter).toBe(1);
      });

      it('should count available environments and save the count in the state', () => {
        expect(gl.environmentsList.EnvironmentsStore.state.availableCounter).toBe(3);
      });

      it('should store environments with same environment_type as sibilings', () => {
        expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(3);

        const parentFolder = gl.environmentsList.EnvironmentsStore.state.environments
        .filter(env => env.children && env.children.length > 0);

        expect(parentFolder[0].children.length).toBe(2);
        expect(parentFolder[0].children[0].environment_type).toBe('review');
        expect(parentFolder[0].children[1].environment_type).toBe('review');
        expect(parentFolder[0].children[0].name).toBe('test-environment');
        expect(parentFolder[0].children[1].name).toBe('test-environment-1');
      });

      it('should sort the environments alphabetically', () => {
        const { environments } = gl.environmentsList.EnvironmentsStore.state;

        expect(environments[0].name).toBe('production');
        expect(environments[1].name).toBe('review');
        expect(environments[1].children[0].name).toBe('test-environment');
        expect(environments[1].children[1].name).toBe('test-environment-1');
        expect(environments[2].name).toBe('review_app');
      });
    });

    describe('toggleFolder', () => {
      beforeEach(() => {
        gl.environmentsList.EnvironmentsStore.storeEnvironments(environmentsList);
      });

      it('should toggle the open property for the given environment', () => {
        gl.environmentsList.EnvironmentsStore.toggleFolder('review');

        const { environments } = gl.environmentsList.EnvironmentsStore.state;
        const environment = environments.filter(env => env['vue-isChildren'] === true && env.name === 'review');

        expect(environment[0].isOpen).toBe(true);
      });
    });
  });
})();
