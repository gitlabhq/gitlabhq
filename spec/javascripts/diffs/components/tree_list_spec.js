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

    localStorage.removeItem('mr_diff_tree_list');

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
          path: 'app/index.js',
          removedLines: 0,
          tempFile: true,
          type: 'blob',
          parentPath: 'app',
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
      vm.search = 'app/index';

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

      expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/scrollToFile', 'app/index.js');
    });

    it('renders as file list when renderTreeList is false', done => {
      vm.renderTreeList = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.file-row').length).toBe(1);

        done();
      });
    });

    it('renders file paths when renderTreeList is false', done => {
      vm.renderTreeList = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-row').textContent).toContain('index.js');

        done();
      });
    });

    it('hides render buttons when input is focused', done => {
      const focusEvent = new Event('focus');

      vm.$el.querySelector('.form-control').dispatchEvent(focusEvent);

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.tree-list-view-toggle').style.display).toBe('none');

        done();
      });
    });

    it('shows render buttons when input is blurred', done => {
      const blurEvent = new Event('blur');
      vm.focusSearch = true;

      vm.$nextTick()
        .then(() => {
          vm.$el.querySelector('.form-control').dispatchEvent(blurEvent);
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.$el.querySelector('.tree-list-view-toggle').style.display).not.toBe('none');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('clearSearch', () => {
    it('resets search', () => {
      vm.search = 'test';

      vm.$el.querySelector('.tree-list-clear-icon').click();

      expect(vm.search).toBe('');
    });
  });

  describe('toggleRenderTreeList', () => {
    it('updates renderTreeList', () => {
      expect(vm.renderTreeList).toBe(true);

      vm.toggleRenderTreeList(false);

      expect(vm.renderTreeList).toBe(false);
    });
  });

  describe('toggleFocusSearch', () => {
    it('updates focusSearch', () => {
      expect(vm.focusSearch).toBe(false);

      vm.toggleFocusSearch(true);

      expect(vm.focusSearch).toBe(true);
    });
  });
});
