import Vue from 'vue';

import SidebarSubscriptions from 'ee/epics/sidebar/components/sidebar_subscriptions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = () => {
  const Component = Vue.extend(SidebarSubscriptions);

  return mountComponent(Component, {
    loading: false,
    subscribed: true,
  });
};

describe('SidebarSubscriptions', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('onToggleSubscription', () => {
      it('emits `toggleSubscription` event on component', () => {
        spyOn(vm, '$emit');
        vm.onToggleSubscription();
        expect(vm.$emit).toHaveBeenCalledWith('toggleSubscription');
      });
    });

    describe('onToggleSidebar', () => {
      it('emits `toggleCollapse` event on component', () => {
        spyOn(vm, '$emit');
        vm.onToggleSidebar();
        expect(vm.$emit).toHaveBeenCalledWith('toggleCollapse');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `block subscriptions`', () => {
      expect(vm.$el.classList.contains('block', 'subscriptions')).toBe(true);
    });

    it('renders subscription toggle element', () => {
      expect(vm.$el.querySelector('.project-feature-toggle')).not.toBeNull();
    });
  });
});
