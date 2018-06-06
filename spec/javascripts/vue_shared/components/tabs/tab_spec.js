import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import Tab from '~/vue_shared/components/tabs/tab.vue';

describe('Tab component', () => {
  const Component = Vue.extend(Tab);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component);
  });

  it('sets localActive to equal active', done => {
    vm.active = true;

    vm.$nextTick(() => {
      expect(vm.localActive).toBe(true);

      done();
    });
  });

  it('sets active class', done => {
    vm.active = true;

    vm.$nextTick(() => {
      expect(vm.$el.classList).toContain('active');

      done();
    });
  });
});
