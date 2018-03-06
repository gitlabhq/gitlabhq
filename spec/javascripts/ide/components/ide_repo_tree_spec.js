import Vue from 'vue';
import store from 'ee/ide/stores';
import ideRepoTree from 'ee/ide/components/ide_repo_tree.vue';
import { file, resetStore } from '../helpers';

describe('IdeRepoTree', () => {
  let vm;

  beforeEach(() => {
    const IdeRepoTree = Vue.extend(ideRepoTree);

    vm = new IdeRepoTree({
      store,
      propsData: {
        treeId: 'abcproject/mybranch',
      },
    });

    vm.$store.state.currentBranch = 'master';
    vm.$store.state.isRoot = true;
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [file()],
    };

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a sidebar', () => {
    const tbody = vm.$el.querySelector('tbody');

    expect(vm.$el.classList.contains('sidebar-mini')).toBeFalsy();
    expect(tbody.querySelector('.repo-file-options')).toBeFalsy();
    expect(tbody.querySelector('.prev-directory')).toBeFalsy();
    expect(tbody.querySelector('.loading-file')).toBeFalsy();
    expect(tbody.querySelector('.file')).toBeTruthy();
  });

  it('renders 3 loading files if tree is loading', (done) => {
    vm.treeId = '123';

    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toEqual(3);

      done();
    });
  });

  it('renders a prev directory if is not root', (done) => {
    vm.$store.state.isRoot = false;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('tbody .prev-directory')).toBeTruthy();

      done();
    });
  });
});
