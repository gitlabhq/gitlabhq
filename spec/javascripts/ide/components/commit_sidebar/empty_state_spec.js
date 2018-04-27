import Vue from 'vue';
import store from '~/ide/stores';
import emptyState from '~/ide/components/commit_sidebar/empty_state.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('IDE commit panel empty state', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(emptyState);

    Vue.set(store.state, 'noChangesStateSvgPath', 'no-changes');
    Vue.set(store.state, 'committedStateSvgPath', 'committed-state');

    vm = createComponentWithStore(Component, store);

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('statusSvg', () => {
    it('uses noChangesStateSvgPath when commit message is empty', () => {
      expect(vm.statusSvg).toBe('no-changes');
      expect(vm.$el.querySelector('img').getAttribute('src')).toBe('no-changes');
    });

    it('uses committedStateSvgPath when commit message exists', done => {
      vm.$store.state.lastCommitMsg = 'testing';

      Vue.nextTick(() => {
        expect(vm.statusSvg).toBe('committed-state');
        expect(vm.$el.querySelector('img').getAttribute('src')).toBe('committed-state');

        done();
      });
    });
  });

  it('renders no changes text when last commit message is empty', () => {
    expect(vm.$el.textContent).toContain('No changes');
  });

  it('renders last commit message when it exists', done => {
    vm.$store.state.lastCommitMsg = 'testing commit message';

    Vue.nextTick(() => {
      expect(vm.$el.textContent).toContain('testing commit message');

      done();
    });
  });
});
