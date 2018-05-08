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

    vm = createComponentWithStore(Component, store);

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders no changes text when last commit message is empty', () => {
    expect(vm.$el.textContent).toContain('No changes');
  });
});
