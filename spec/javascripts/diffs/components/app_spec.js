import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import App from '~/diffs/components/app.vue';
import NoChanges from '~/diffs/components/no_changes.vue';
import DiffFile from '~/diffs/components/diff_file.vue';
import Mousetrap from 'mousetrap';
import createDiffsStore from '../create_diffs_store';

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  let store;
  let wrapper;

  function createComponent(props = {}, extendStore = () => {}) {
    const localVue = createLocalVue();

    localVue.use(Vuex);

    store = createDiffsStore();
    store.state.diffs.isLoading = false;

    extendStore(store);

    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      propsData: {
        endpoint: `${TEST_HOST}/diff/endpoint`,
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        ...props,
      },
      store,
    });
  }

  beforeEach(() => {
    // setup globals (needed for component to mount :/)
    window.mrTabs = jasmine.createSpyObj('mrTabs', ['resetViewContainer']);
    window.mrTabs.expandViewContainer = jasmine.createSpy();
  });

  afterEach(() => {
    // reset globals
    window.mrTabs = oldMrTabs;

    // reset component
    wrapper.destroy();
  });

  it('does not show commit info', () => {
    createComponent();

    expect(wrapper.contains('.blob-commit-info')).toBe(false);
  });

  describe('row highlighting', () => {
    beforeEach(() => {
      window.location.hash = 'ABC_123';
    });

    it('sets highlighted row if hash exists in location object', done => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      setTimeout(() => {
        expect(store.state.diffs.highlightedRow).toBe('ABC_123');

        done();
      });
    });

    it('marks current diff file based on currently highlighted row', done => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      setTimeout(() => {
        expect(store.state.diffs.currentDiffFileId).toBe('ABC');

        done();
      });
    });
  });

  describe('resizable', () => {
    afterEach(() => {
      localStorage.removeItem('mr_tree_list_width');
    });

    it('sets initial width when no localStorage has been set', () => {
      createComponent();

      expect(wrapper.vm.treeWidth).toEqual(320);
    });

    it('sets initial width to localStorage size', () => {
      localStorage.setItem('mr_tree_list_width', '200');

      createComponent();

      expect(wrapper.vm.treeWidth).toEqual(200);
    });

    it('sets width of tree list', () => {
      createComponent();

      expect(wrapper.find('.js-diff-tree-list').element.style.width).toEqual('320px');
    });
  });

  it('marks current diff file based on currently highlighted row', done => {
    createComponent({
      shouldShow: true,
    });

    // Component uses $nextTick so we wait until that has finished
    setTimeout(() => {
      expect(store.state.diffs.currentDiffFileId).toBe('ABC');

      done();
    });
  });

  describe('empty state', () => {
    it('renders empty state when no diff files exist', () => {
      createComponent();

      expect(wrapper.contains(NoChanges)).toBe(true);
    });

    it('does not render empty state when diff files exist', () => {
      createComponent({}, () => {
        store.state.diffs.diffFiles.push({
          id: 1,
        });
      });

      expect(wrapper.contains(NoChanges)).toBe(false);
      expect(wrapper.findAll(DiffFile).length).toBe(1);
    });

    it('does not render empty state when versions match', () => {
      createComponent({}, () => {
        store.state.diffs.startVersion = { version_index: 1 };
        store.state.diffs.mergeRequestDiff = { version_index: 1 };
      });

      expect(wrapper.contains(NoChanges)).toBe(false);
    });
  });

  describe('keyboard shortcut navigation', () => {
    const mappings = {
      '[': -1,
      k: -1,
      ']': +1,
      j: +1,
    };
    let spy;

    describe('visible app', () => {
      beforeEach(() => {
        spy = jasmine.createSpy('spy');

        createComponent({
          shouldShow: true,
        });
        wrapper.setMethods({
          jumpToFile: spy,
        });
      });

      it('calls `jumpToFile()` with correct parameter whenever pre-defined key is pressed', done => {
        wrapper.vm
          .$nextTick()
          .then(() => {
            Object.keys(mappings).forEach(function(key) {
              Mousetrap.trigger(key);

              expect(spy.calls.mostRecent().args).toEqual([mappings[key]]);
            });

            expect(spy.calls.count()).toEqual(Object.keys(mappings).length);
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not call `jumpToFile()` when unknown key is pressed', done => {
        wrapper.vm
          .$nextTick()
          .then(() => {
            Mousetrap.trigger('d');

            expect(spy).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('hideen app', () => {
      beforeEach(() => {
        spy = jasmine.createSpy('spy');

        createComponent({
          shouldShow: false,
        });
        wrapper.setMethods({
          jumpToFile: spy,
        });
      });

      it('stops calling `jumpToFile()` when application is hidden', done => {
        wrapper.vm
          .$nextTick()
          .then(() => {
            Object.keys(mappings).forEach(function(key) {
              Mousetrap.trigger(key);

              expect(spy).not.toHaveBeenCalled();
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('jumpToFile', () => {
    let spy;

    beforeEach(() => {
      spy = jasmine.createSpy();

      createComponent({}, () => {
        store.state.diffs.diffFiles = [
          { file_hash: '111', file_path: '111.js' },
          { file_hash: '222', file_path: '222.js' },
          { file_hash: '333', file_path: '333.js' },
        ];
      });

      wrapper.setMethods({
        scrollToFile: spy,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('jumps to next and previous files in the list', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.vm.jumpToFile(+1);

          expect(spy.calls.mostRecent().args).toEqual(['222.js']);
          store.state.diffs.currentDiffFileId = '222';
          wrapper.vm.jumpToFile(+1);

          expect(spy.calls.mostRecent().args).toEqual(['333.js']);
          store.state.diffs.currentDiffFileId = '333';
          wrapper.vm.jumpToFile(-1);

          expect(spy.calls.mostRecent().args).toEqual(['222.js']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not jump to previous file from the first one', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          store.state.diffs.currentDiffFileId = '333';

          expect(wrapper.vm.currentDiffIndex).toEqual(2);

          wrapper.vm.jumpToFile(+1);

          expect(wrapper.vm.currentDiffIndex).toEqual(2);
          expect(spy).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not jump to next file from the last one', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.currentDiffIndex).toEqual(0);

          wrapper.vm.jumpToFile(-1);

          expect(wrapper.vm.currentDiffIndex).toEqual(0);
          expect(spy).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
