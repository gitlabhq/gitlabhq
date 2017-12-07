import Vue from 'vue';
import store from '~/ide/stores';
import ideContextBar from '~/ide/components/ide_context_bar.vue';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';

describe('Multi-file editor right context bar', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ideContextBar);

    vm = createComponentWithStore(Component, store).$mount();

    vm.$store.state.rightPanelCollapsed = false;
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed', () => {
    beforeEach((done) => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    it('adds collapsed class', () => {
      expect(vm.$el.querySelector('.is-collapsed')).not.toBeNull();
    });

    it('shows correct icon', () => {
      expect(vm.currentIcon).toBe('angle-double-left');
    });
  });

  it('clicking toggle collapse button collapses the bar', () => {
    vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

    expect(vm).toHaveBeenCalledWith('toggleCollapsed');
  });
});
