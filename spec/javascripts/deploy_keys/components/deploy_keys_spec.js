import Vue from 'vue';
import deployKeysComponent from '~/deploy_keys/components/deploy_keys';
import DeployKeysService from '~/deploy_keys/services/deploy_keys_service';

fdescribe('DeployKeys', () => {
  describe('created', () => {
    it('should call service.get()', () => {
      const DeployKeysComponent = Vue.extend(deployKeysComponent);
      const component = new DeployKeysComponent();

      spyOn(DeployKeysService.prototype, 'constructor').and.callFake(() => {
        return {
          get: () => Promise.resolve({
            data: {
              enabled_keys: [],
              available_project_keys: [],
              public_keys: [],
            }
          }),
        };
      });

      component.$mount();

      setTimeout(() => expect(component.loaded).toEqual(true), 0);
    });

    it('should dismiss loaded when service.get() fails', () => {
      const DeployKeysComponent = Vue.extend(deployKeysComponent);
      const component = new DeployKeysComponent();

      spyOn(DeployKeysService.prototype, 'constructor').and.callFake(() => {
        return {
          get: () => Promise.reject(),
        };
      });

      component.$mount();

      setTimeout(() => expect(component.loaded).toEqual(true), 0);
    });
  });

  describe('methods', () => {
    describe('enableKeyInSectionIndex', () => {
      it('should return true if index is greater than 0', () => {
        const DeployKeysComponent = Vue.extend(deployKeysComponent);
        const component = new DeployKeysComponent().$mount();

        expect(component.enableKeyInSectionIndex(1)).toEqual(true);
      });
    });
  });

  describe('template', () => {
    it('should render section if renderSection()', () => {});
  });
});
