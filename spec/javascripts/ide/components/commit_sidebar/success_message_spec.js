import Vue from 'vue';
import store from '~/ide/stores';
import successMessage from '~/ide/components/commit_sidebar/success_message.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('IDE commit panel successful commit state', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(successMessage);

    vm = createComponentWithStore(Component, store, {
      committedStateSvgPath: 'committed-state',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders last commit message when it exists', done => {
    vm.$store.state.lastCommitMsg = 'testing commit message';

    Vue.nextTick(() => {
      expect(vm.$el.textContent).toContain('testing commit message');

      done();
    });
  });
});
