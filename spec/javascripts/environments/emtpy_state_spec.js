import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import emptyState from '~/environments/components/empty_state.vue';

describe('environments empty state', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(emptyState);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('With permissions', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        newPath: 'foo',
        canCreateEnvironment: true,
        helpPath: 'bar',
      });
    });

    it('renders empty state and new environment button', () => {
      expect(vm.$el.querySelector('.js-blank-state-title').textContent.trim()).toEqual(
        "You don't have any environments right now",
      );

      expect(vm.$el.querySelector('.js-new-environment-button').getAttribute('href')).toEqual(
        'foo',
      );
    });
  });

  describe('Without permission', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        newPath: 'foo',
        canCreateEnvironment: false,
        helpPath: 'bar',
      });
    });

    it('renders empty state without new button', () => {
      expect(vm.$el.querySelector('.js-blank-state-title').textContent.trim()).toEqual(
        "You don't have any environments right now",
      );

      expect(vm.$el.querySelector('.js-new-environment-button')).toBeNull();
    });
  });
});
