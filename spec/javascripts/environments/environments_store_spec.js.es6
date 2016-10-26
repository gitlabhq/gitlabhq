//= require vue
//= require vue-resource
//= require lib/utils/url_utility
//= require environments/services/environments_service
//= require environments/stores/environments_store
//= require ./mock_data
// 

(() => {
  beforeEach(() => {
    gl.environmentsService = new EnvironmentsService('test/environments');
    gl.environmentsList.EnvironmentsStore.create();
  });
  
  describe('Store', () => {
    it('starts with a blank state', () => {
      expect(gl.environmentsList.EnvironmentsStore.state.environments.length).toBe(0);
    });

  });
})();
