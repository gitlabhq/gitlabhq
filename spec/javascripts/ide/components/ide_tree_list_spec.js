import Vue from 'vue';
import IdeTreeList from '~/ide/components/ide_tree_list.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { resetStore, file } from '../helpers';
import { projectData } from '../mock_data';

describe('IDE tree list', () => {
  const Component = Vue.extend(IdeTreeList);
  const normalBranchTree = [file('fileName')];
  const emptyBranchTree = [];
  let vm;

  const bootstrapWithTree = (tree = normalBranchTree) => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);
    Vue.set(store.state.trees, 'abcproject/master', {
      tree,
      loading: false,
    });

    vm = createComponentWithStore(Component, store, {
      viewerType: 'edit',
    });
  };

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('normal branch', () => {
    beforeEach(() => {
      bootstrapWithTree();

      spyOn(vm, 'updateViewer').and.callThrough();

      vm.$mount();
    });

    it('updates viewer on mount', () => {
      expect(vm.updateViewer).toHaveBeenCalledWith('edit');
    });

    it('renders loading indicator', done => {
      store.state.trees['abcproject/master'].loading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.multi-file-loading-container')).not.toBeNull();
        expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toBe(3);

        done();
      });
    });

    it('renders list of files', () => {
      expect(vm.$el.textContent).toContain('fileName');
    });

    it('does not render moved entries', done => {
      const tree = [file('moved entry'), file('normal entry')];
      tree[0].moved = true;
      store.state.trees['abcproject/master'].tree = tree;
      const container = vm.$el.querySelector('.ide-tree-body');

      vm.$nextTick(() => {
        expect(container.children.length).toBe(1);
        expect(vm.$el.textContent).not.toContain('moved entry');
        expect(vm.$el.textContent).toContain('normal entry');
        done();
      });
    });
  });

  describe('empty-branch state', () => {
    beforeEach(() => {
      bootstrapWithTree(emptyBranchTree);

      spyOn(vm, 'updateViewer').and.callThrough();

      vm.$mount();
    });

    it('does not load files if the branch is empty', () => {
      expect(vm.$el.textContent).not.toContain('fileName');
      expect(vm.$el.textContent).toContain('No files');
    });
  });
});
