import Vue from 'vue';
import IdeTreeList from '~/ide/components/ide_tree_list.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { resetStore, file } from '../helpers';
import { projectData } from '../mock_data';

describe('IDE tree list', () => {
  const Component = Vue.extend(IdeTreeList);
  let vm;

  beforeEach(() => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);
    Vue.set(store.state.trees, 'abcproject/master', {
      tree: [file('fileName')],
      loading: false,
    });

    vm = createComponentWithStore(Component, store, {
      viewerType: 'edit',
    });

    spyOn(vm, 'updateViewer').and.callThrough();

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
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
});
