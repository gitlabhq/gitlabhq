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
    expect(vm.$el.classList.contains('sidebar-mini')).toBeFalsy();
    expect(vm.$el.querySelector('.repo-file-options')).toBeFalsy();
    expect(vm.$el.querySelector('.loading-file')).toBeFalsy();
    expect(vm.$el.querySelector('.file')).toBeTruthy();
  });

  it('renders 3 loading files if tree is loading', (done) => {
    vm.$store.state.trees['123'] = {
      tree: [],
      loading: true,
    };
    vm.treeId = '123';

    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toEqual(3);

      done();
    });
  });
});
