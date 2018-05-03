import Vue from 'vue';
import store from '~/ide/stores';
import emptyState from '~/ide/components/commit_sidebar/empty_state.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('IDE commit panel empty state', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(emptyState);

    vm = createComponentWithStore(Component, store, {
      noChangesStateSvgPath: 'no-changes',
      committedStateSvgPath: 'committed-state',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders no changes text when last commit message is empty', () => {
    expect(vm.$el.textContent).toContain('No changes');
  });

  describe('toggle button', () => {
    it('calls store action', () => {
      spyOn(vm, 'toggleRightPanelCollapsed');

      vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

      expect(vm.toggleRightPanelCollapsed).toHaveBeenCalled();
    });

    it('renders collapsed class', done => {
      vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.is-collapsed')).not.toBeNull();

        done();
      });
    });
  });

  describe('collapsed state', () => {
    beforeEach(done => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    it('does not render text & svg', () => {
      expect(vm.$el.querySelector('img')).toBeNull();
      expect(vm.$el.textContent).not.toContain('No changes');
    });
  });
});
