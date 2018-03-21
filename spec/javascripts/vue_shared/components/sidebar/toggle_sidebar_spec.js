import Vue from 'vue';
import toggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('toggleSidebar', () => {
  let vm;
  beforeEach(() => {
    const ToggleSidebar = Vue.extend(toggleSidebar);
    vm = mountComponent(ToggleSidebar, {
      collapsed: true,
    });
  });

  it('should render << when collapsed', () => {
    expect(vm.$el.querySelector('.fa').classList.contains('fa-angle-double-left')).toEqual(true);
  });

  it('should render >> when collapsed', () => {
    vm.collapsed = false;
    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.fa').classList.contains('fa-angle-double-right')).toEqual(true);
    });
  });

  it('should emit toggle event when button clicked', () => {
    const toggle = jasmine.createSpy();
    vm.$on('toggle', toggle);
    vm.$el.click();

    expect(toggle).toHaveBeenCalled();
  });
});
