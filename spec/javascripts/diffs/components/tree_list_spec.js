import Vue from 'vue';
import Vuex from 'vuex';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Diffs tree list component', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(TreeList);
  });

  beforeEach(() => {
    Vue.use(Vuex);

    const store = new Vuex.Store({
      modules: {
        diffs: createStore(),
      },
    });

    // Setup initial state
    store.state.diffs.addedLines = 10;
    store.state.diffs.removedLines = 20;
    store.state.diffs.diffFiles.push('test');

    vm = mountComponentWithStore(Component, { store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders diff stats', () => {
    expect(vm.$el.textContent).toContain('1 changed file');
    expect(vm.$el.textContent).toContain('10 additions');
    expect(vm.$el.textContent).toContain('20 deletions');
  });

  it('renders empty text', () => {
    expect(vm.$el.textContent).toContain('No files found');
  });

  describe('with files', () => {
    beforeEach(done => {
      Object.assign(vm.$store.state.diffs.treeEntries, {
        'index.js': {
          addedLines: 0,
          changed: true,
          deleted: false,
          fileHash: 'test',
          key: 'index.js',
          name: 'index.js',
          path: 'index.js',
          removedLines: 0,
          tempFile: true,
          type: 'blob',
        },
        app: {
          key: 'app',
          path: 'app',
          name: 'app',
          type: 'tree',
          tree: [],
        },
      });
      vm.$store.state.diffs.tree = [
        vm.$store.state.diffs.treeEntries['index.js'],
        vm.$store.state.diffs.treeEntries.app,
      ];

      vm.$nextTick(done);
    });

    it('renders tree', () => {
      expect(vm.$el.querySelectorAll('.file-row').length).toBe(2);
      expect(vm.$el.querySelectorAll('.file-row')[0].textContent).toContain('index.js');
      expect(vm.$el.querySelectorAll('.file-row')[1].textContent).toContain('app');
    });

    it('filters tree list to blobs matching search', done => {
      vm.search = 'index';

      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.file-row').length).toBe(1);
        expect(vm.$el.querySelectorAll('.file-row')[0].textContent).toContain('index.js');

        done();
      });
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      spyOn(vm.$store, 'dispatch').and.stub();

      vm.$el.querySelectorAll('.file-row')[1].click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/toggleTreeOpen', 'app');
    });

    it('calls scrollToFile when clicking blob', () => {
      spyOn(vm.$store, 'dispatch').and.stub();

      vm.$el.querySelector('.file-row').click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/scrollToFile', 'index.js');
    });
  });

  describe('clearSearch', () => {
    it('resets search', () => {
      vm.search = 'test';

      vm.$el.querySelector('.tree-list-clear-icon').click();

      expect(vm.search).toBe('');
    });
  });
});
