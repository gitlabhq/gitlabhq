import Vue from 'vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import createComponent from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('IdeRepoTree', () => {
  let vm;
  let tree;

  beforeEach(() => {
    const IdeRepoTree = Vue.extend(IdeTree);

    tree = {
      tree: [file()],
      loading: false,
    };

    vm = createComponent(IdeRepoTree, {
      tree,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a sidebar', () => {
    expect(vm.$el.querySelector('.loading-file')).toBeNull();
    expect(vm.$el.querySelector('.file')).not.toBeNull();
  });

  it('renders 3 loading files if tree is loading', done => {
    tree.loading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toEqual(3);

      done();
    });
  });
});
