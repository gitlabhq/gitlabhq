import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import toggleButton from '~/vue_shared/components/toggle_button.vue';

describe('Toggle Button', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(toggleButton);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('render output', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        value: true,
        name: 'foo',
      });
    });

    it('renders input with provided name', () => {
      expect(vm.$el.querySelector('input').getAttribute('name')).toEqual('foo');
    });

    it('renders input with provided value', () => {
      expect(vm.$el.querySelector('input').getAttribute('value')).toEqual('true');
    });

    it('renders input status icon', () => {
      expect(vm.$el.querySelectorAll('span.toggle-icon').length).toEqual(1);
      expect(vm.$el.querySelectorAll('svg.s16.toggle-icon-svg').length).toEqual(1);
    });
  });

  describe('is-checked', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        value: true,
      });

      spyOn(vm, '$emit');
    });

    it('renders is checked class', () => {
      expect(vm.$el.querySelector('button').classList.contains('is-checked')).toEqual(true);
    });

    it('sets aria-label representing toggle state', () => {
      vm.value = true;

      expect(vm.ariaLabel).toEqual('Toggle Status: ON');

      vm.value = false;

      expect(vm.ariaLabel).toEqual('Toggle Status: OFF');
    });

    it('emits change event when clicked', () => {
      vm.$el.querySelector('button').click();

      expect(vm.$emit).toHaveBeenCalledWith('change', false);
    });
  });

  describe('is-disabled', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        value: true,
        disabledInput: true,
      });
      spyOn(vm, '$emit');
    });

    it('renders disabled button', () => {
      expect(vm.$el.querySelector('button').classList.contains('is-disabled')).toEqual(true);
    });

    it('does not emit change event when clicked', () => {
      vm.$el.querySelector('button').click();

      expect(vm.$emit).not.toHaveBeenCalled();
    });
  });

  describe('is-loading', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        value: true,
        isLoading: true,
      });
    });

    it('renders loading class', () => {
      expect(vm.$el.querySelector('button').classList.contains('is-loading')).toEqual(true);
    });
  });
});
