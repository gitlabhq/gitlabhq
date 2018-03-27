import Vue from 'vue';
import loadingButton from '~/vue_shared/components/loading_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

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

      expect(label.textContent.trim()).toEqual(LABEL);
    });
  });

  describe('container class', () => {
    it('should default to btn btn-align-content', () => {
      vm = mountComponent(LoadingButton, {});
      expect(vm.$el.classList.contains('btn')).toEqual(true);
      expect(vm.$el.classList.contains('btn-align-content')).toEqual(true);
    });

    it('should be configurable through props', () => {
      vm = mountComponent(LoadingButton, {
        containerClass: 'test-class',
      });
      expect(vm.$el.classList.contains('btn')).toEqual(false);
      expect(vm.$el.classList.contains('btn-align-content')).toEqual(false);
      expect(vm.$el.classList.contains('test-class')).toEqual(true);
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
      });
      spyOn(vm, '$emit');

      vm.$el.click();

      expect(vm.$emit).not.toHaveBeenCalled();
    });
  });
});
