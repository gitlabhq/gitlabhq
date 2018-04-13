import Vue from 'vue';
import store from '~/ide/stores';
import FindFileComponent from '~/ide/components/file_finder/index.vue';
import router from '~/ide/ide_router';
import { file, resetStore } from '../../helpers';
import { mountComponentWithStore } from '../../../helpers/vue_mount_component_helper';

describe('IDE File finder item spec', () => {
  const Component = Vue.extend(FindFileComponent);
  let vm;

  beforeEach(done => {
    setFixtures('<div id="app"></div>');

    vm = mountComponentWithStore(Component, {
      store,
      el: '#app',
      props: {
        index: 0,
      },
    });

    setTimeout(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('with entries', () => {
    beforeEach(done => {
      Vue.set(vm.$store.state.entries, 'folder', {
        ...file('folder'),
        path: 'folder',
        type: 'folder',
      });

      Vue.set(vm.$store.state.entries, 'index.js', {
        ...file('index.js'),
        path: 'index.js',
        type: 'blob',
        url: '/index.jsurl',
      });

      Vue.set(vm.$store.state.entries, 'component.js', {
        ...file('component.js'),
        path: 'component.js',
        type: 'blob',
      });

      setTimeout(done);
    });

    it('renders list of blobs', () => {
      expect(vm.$el.textContent).toContain('index.js');
      expect(vm.$el.textContent).toContain('component.js');
      expect(vm.$el.textContent).not.toContain('folder');
    });

    it('filters entries', done => {
      vm.searchText = 'index';

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain('index.js');
        expect(vm.$el.textContent).not.toContain('component.js');

        done();
      });
    });

    it('shows clear button when searchText is not empty', done => {
      vm.searchText = 'index';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-input-clear').classList).toContain('show');
        expect(vm.$el.querySelector('.dropdown-input-search').classList).toContain('hidden');

        done();
      });
    });

    it('clear button resets searchText', done => {
      vm.searchText = 'index';

      vm
        .$nextTick()
        .then(() => {
          vm.$el.querySelector('.dropdown-input-clear').click();
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.searchText).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });

    it('clear button focues search input', done => {
      spyOn(vm.$refs.searchInput, 'focus');
      vm.searchText = 'index';

      vm
        .$nextTick()
        .then(() => {
          vm.$el.querySelector('.dropdown-input-clear').click();
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.$refs.searchInput.focus).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    describe('listShowCount', () => {
      it('returns 1 when no filtered entries exist', done => {
        vm.searchText = 'testing 123';

        vm.$nextTick(() => {
          expect(vm.listShowCount).toBe(1);

          done();
        });
      });

      it('returns entries length when not filtered', () => {
        expect(vm.listShowCount).toBe(2);
      });
    });

    describe('listHeight', () => {
      it('returns 55 when entries exist', () => {
        expect(vm.listHeight).toBe(55);
      });

      it('returns 33 when entries dont exist', done => {
        vm.searchText = 'testing 123';

        vm.$nextTick(() => {
          expect(vm.listHeight).toBe(33);

          done();
        });
      });
    });

    describe('filteredBlobsLength', () => {
      it('returns length of filtered blobs', done => {
        vm.searchText = 'index';

        vm.$nextTick(() => {
          expect(vm.filteredBlobsLength).toBe(1);

          done();
        });
      });
    });

    describe('watches', () => {
      describe('searchText', () => {
        it('resets focusedIndex when updated', done => {
          vm.focusedIndex = 1;
          vm.searchText = 'test';

          vm.$nextTick(() => {
            expect(vm.focusedIndex).toBe(0);

            done();
          });
        });
      });

      describe('fileFindVisible', () => {
        it('returns searchText when false', done => {
          vm.searchText = 'test';
          vm.$store.state.fileFindVisible = true;

          vm
            .$nextTick()
            .then(() => {
              vm.$store.state.fileFindVisible = false;
            })
            .then(vm.$nextTick)
            .then(() => {
              expect(vm.searchText).toBe('');
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });

    describe('openFile', () => {
      beforeEach(() => {
        spyOn(router, 'push');
        spyOn(vm, 'toggleFileFinder');
      });

      it('closes file finder', () => {
        vm.openFile(vm.$store.state.entries['index.js']);

        expect(vm.toggleFileFinder).toHaveBeenCalled();
      });

      it('pushes to router', () => {
        vm.openFile(vm.$store.state.entries['index.js']);

        expect(router.push).toHaveBeenCalledWith('/project/index.jsurl');
      });
    });

    describe('onKeyup', () => {
      it('opens file on enter key', done => {
        const event = new CustomEvent('keyup');
        event.keyCode = 13;

        spyOn(vm, 'openFile');

        vm.$refs.searchInput.dispatchEvent(event);

        vm.$nextTick(() => {
          expect(vm.openFile).toHaveBeenCalledWith(vm.$store.state.entries['index.js']);

          done();
        });
      });

      it('closes file finder on esc key', done => {
        const event = new CustomEvent('keyup');
        event.keyCode = 27;

        spyOn(vm, 'toggleFileFinder');

        vm.$refs.searchInput.dispatchEvent(event);

        vm.$nextTick(() => {
          expect(vm.toggleFileFinder).toHaveBeenCalled();

          done();
        });
      });
    });

    describe('onKeyDown', () => {
      let el;

      beforeEach(() => {
        el = vm.$refs.searchInput;
      });

      describe('up key', () => {
        const event = new CustomEvent('keydown');
        event.keyCode = 38;

        it('resets to last index when at top', () => {
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(1);
        });

        it('minus 1 from focusedIndex', () => {
          vm.focusedIndex = 1;

          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(0);
        });
      });

      describe('down key', () => {
        const event = new CustomEvent('keydown');
        event.keyCode = 40;

        it('resets to first index when at bottom', () => {
          vm.focusedIndex = 1;
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(0);
        });

        it('adds 1 to focusedIndex', () => {
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(1);
        });
      });
    });
  });

  describe('without entries', () => {
    it('renders loading text when loading', done => {
      store.state.loading = true;

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain('Loading...');

        done();
      });
    });

    it('renders no files text', () => {
      expect(vm.$el.textContent).toContain('No files found.');
    });
  });
});
