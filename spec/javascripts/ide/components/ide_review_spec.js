import Vue from 'vue';
import IdeReview from '~/ide/components/ide_review.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { resetStore, file } from '../helpers';
import { projectData } from '../mock_data';

describe('IDE review mode', () => {
  const Component = Vue.extend(IdeReview);
  let vm;

  beforeEach(() => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);
    Vue.set(store.state.trees, 'abcproject/master', {
      tree: [file('fileName')],
      loading: false,
    });

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders list of files', () => {
    expect(vm.$el.textContent).toContain('fileName');
  });
});
