import Vue from 'vue';
import store from '~/ide/stores';
import ideContextBar from '~/ide/components/ide_context_bar.vue';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';

describe('Multi-file editor right context bar', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ideContextBar);

    vm = createComponentWithStore(Component, store).$mount();

    vm.$store.state.rightBarCollapsed = false;
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed', () => {
    beforeEach((done) => {
      vm.$store.state.rightBarCollapsed = true;

      Vue.nextTick(done);
    });

    it('adds collapsed class', () => {
      expect(vm.$el.querySelector('.is-collapsed')).not.toBeNull();
    });

    it('shows correct icon', () => {
      expect(vm.currentIcon).toBe('angle-double-left');
    });
  });

  it('clicking toggle collapse button emits toggle event', () => {
    spyOn(vm, '$emit');

    vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

    expect(vm).toHaveBeenCalledWith('toggleCollapsed');
  });
});
