//= require vue
//= require environments/stores/environmnets_store
//= require ./mock_data

(() => {

  beforeEach(() => {
    gl.environmentsList.EnvironmentsStore.create();
  });

  describe('Store', () => {
    it('should start with a blank state', () => {
      expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.stoppedCounter).toBe(0);
      expect(gl.environmentsList.EnvironmentsStore.state.availableCounter).toBe(0)
    });

    describe('store environments', () => {
      beforeEach(() => {
          gl.environmentsList.EnvironmentsStore.storeEnvironments(environmentsList);
      });

      it('should count stopped environments and save the count in the state', () => {


        expect(gl.environmentsList.EnvironmentsStore.state.stoppedCounter).toBe(1);
      });

      it('should count available environments and save the count in the state', () => {

        expect(gl.environmentsList.EnvironmentsStore.state.availableCounter).toBe(2);
      });

      it('should store environments with same environment_type as sibilings', () => {

        expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(2);
        
        const parentFolder = gl.environmentsList.EnvironmentsStore.state.environments.filter((env) => {
          return env.children && env.children.length > 0;
        });

        expect(parentFolder[0].children.length).toBe(2);
        expect(parentFolder[0].children[0].environment_type).toBe('review');
        expect(parentFolder[0].children[1].environment_type).toBe('review');
        expect(parentFolder[0].children[0].name).toBe('review/test-environment')
        expect(parentFolder[0].children[1].name).toBe('review/test-environment-1');
      });

      it('should sort the environments alphabetically', () => {
        const { environments } = gl.environmentsList.EnvironmentsStore.state;

        expect(environments[0].name).toBe('production');
        expect(environments[1].children[0].name).toBe('review/test-environment');
        expect(environments[1].children[1].name).toBe('review/test-environment-1');
      });
    });
  });
})();
