import Vue from 'vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { resetStore, file } from '../helpers';
import { projectData } from '../mock_data';

describe('IdeRepoTree', () => {
  let vm;

  beforeEach(() => {
    const IdeRepoTree = Vue.extend(IdeTree);

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);
    Vue.set(store.state.trees, 'abcproject/master', {
      tree: [file('fileName')],
      loading: false,
    });

    vm = createComponentWithStore(IdeRepoTree, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders loading', done => {
    vm.currentTree.loading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toBe(3);
      done();
    });
  });

  it('renders list of files', () => {
    expect(vm.$el.textContent).toContain('fileName');
  });
});
