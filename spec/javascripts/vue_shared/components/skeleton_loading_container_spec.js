import Vue from 'vue';
import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Skeleton loading container', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(skeletonLoadingContainer);
    vm = mountComponent(component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders 6 skeleton lines by default', () => {
    expect(vm.$el.querySelector('.skeleton-line-6')).not.toBeNull();
  });

  it('renders in full mode by default', () => {
    expect(vm.$el.classList.contains('animation-container-small')).toBeFalsy();
  });

  describe('small', () => {
    beforeEach((done) => {
      vm.small = true;

      Vue.nextTick(done);
    });

    it('renders in small mode', () => {
      expect(vm.$el.classList.contains('animation-container-small')).toBeTruthy();
    });
  });

  describe('lines', () => {
    beforeEach((done) => {
      vm.lines = 5;

      Vue.nextTick(done);
    });

    it('renders 5 lines', () => {
      expect(vm.$el.querySelector('.skeleton-line-5')).not.toBeNull();
      expect(vm.$el.querySelector('.skeleton-line-6')).toBeNull();
    });
  });
});
