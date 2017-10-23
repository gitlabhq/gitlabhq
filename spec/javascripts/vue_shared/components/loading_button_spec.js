import Vue from 'vue';
import loadingButton from '~/vue_shared/components/loading_button.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

const LABEL = 'Hello';

describe('LoadingButton', function () {
  let vm;
  let LoadingButton;

  beforeEach(() => {
    LoadingButton = Vue.extend(loadingButton);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('loading spinner', () => {
    it('shown when loading', () => {
      vm = mountComponent(LoadingButton, {
        loading: true,
      });

      expect(vm.$el.querySelector('.js-loading-button-icon')).toBeDefined();
    });
  });

  describe('disabled state', () => {
    it('disabled when loading', () => {
      vm = mountComponent(LoadingButton, {
        loading: true,
      });

      expect(vm.$el.disabled).toEqual(true);
    });

    it('not disabled when normal', () => {
      vm = mountComponent(LoadingButton, {
        loading: false,
      });

      expect(vm.$el.disabled).toEqual(false);
    });
  });

  describe('label', () => {
    it('shown when normal', () => {
      vm = mountComponent(LoadingButton, {
        loading: false,
        label: LABEL,
      });
      const label = vm.$el.querySelector('.js-loading-button-label');

      expect(label.textContent.trim()).toEqual(LABEL);
    });

    it('shown when loading', () => {
      vm = mountComponent(LoadingButton, {
        loading: true,
        label: LABEL,
      });
      const label = vm.$el.querySelector('.js-loading-button-label');
      const spacer = vm.$el.querySelector('.js-loading-button-spacer');

      expect(label.textContent.trim()).toEqual(LABEL);
      expect(spacer).toBeDefined();
    });
  });

  describe('click callback prop', () => {
    it('calls given callback when normal', () => {
      vm = mountComponent(LoadingButton, {
        loading: false,
      });
      spyOn(vm, '$emit');

      vm.$el.click();

      expect(vm.$emit).toHaveBeenCalledWith('click', jasmine.any(Object));
    });

    it('does not call given callback when disabled because of loading', () => {
      vm = mountComponent(LoadingButton, {
        loading: true,
        indeterminate: true,
      });
      spyOn(vm, '$emit');

      vm.$el.click();

      expect(vm.$emit).not.toHaveBeenCalled();
    });
  });
});
