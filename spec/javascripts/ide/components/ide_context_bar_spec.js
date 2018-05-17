import Vue from 'vue';
import store from '~/ide/stores';
import ideContextBar from '~/ide/components/ide_context_bar.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Multi-file editor right context bar', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ideContextBar);

    vm = createComponentWithStore(Component, store, {
      noChangesStateSvgPath: 'svg',
      committedStateSvgPath: 'svg',
    });

    vm.$store.state.rightPanelCollapsed = false;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed', () => {
    beforeEach(done => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    // TODO: https://gitlab.com/gitlab-org/gitlab-ce/issues/45985
    // eslint-disable-next-line jasmine/no-disabled-tests
    xit('adds collapsed class', () => {
      expect(vm.$el.querySelector('.is-collapsed')).not.toBeNull();
    });
  });
});
