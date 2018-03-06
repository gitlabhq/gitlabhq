import Vue from 'vue';
import store from 'ee/ide/stores';
import commitActions from 'ee/ide/components/commit_sidebar/actions.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from 'spec/ide/helpers';

describe('IDE commit sidebar actions', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(commitActions);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = 'master';

    vm.$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders 3 groups', () => {
    expect(vm.$el.querySelectorAll('input[type="radio"]').length).toBe(3);
  });

  it('renders current branch text', () => {
    expect(vm.$el.textContent).toContain('Commit to master branch');
  });
});
