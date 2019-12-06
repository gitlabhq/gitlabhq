import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/ide/stores';
import modal from '~/ide/components/new_dropdown/modal.vue';

describe('new file modal component', () => {
  const Component = Vue.extend(modal);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  ['tree', 'blob'].forEach(type => {
    describe(type, () => {
      beforeEach(() => {
        const store = createStore();
        store.state.entryModal = {
          type,
          path: '',
          entry: {
            path: '',
          },
        };

        vm = createComponentWithStore(Component, store).$mount();

        vm.name = 'testing';
      });

      it(`sets modal title as ${type}`, () => {
        const title = type === 'tree' ? 'directory' : 'file';

        expect(vm.$el.querySelector('.modal-title').textContent.trim()).toBe(`Create new ${title}`);
      });

      it(`sets button label as ${type}`, () => {
        const title = type === 'tree' ? 'directory' : 'file';

        expect(vm.$el.querySelector('.btn-success').textContent.trim()).toBe(`Create ${title}`);
      });

      it(`sets form label as ${type}`, () => {
        expect(vm.$el.querySelector('.label-bold').textContent.trim()).toBe('Name');
      });

      it(`${type === 'tree' ? 'does not show' : 'shows'} file templates`, () => {
        const templateFilesEl = vm.$el.querySelector('.file-templates');
        if (type === 'tree') {
          expect(templateFilesEl).toBeNull();
        } else {
          expect(templateFilesEl instanceof Element).toBeTruthy();
        }
      });

      describe('createEntryInStore', () => {
        it('$emits create', () => {
          spyOn(vm, 'createTempEntry');

          vm.submitForm();

          expect(vm.createTempEntry).toHaveBeenCalledWith({
            name: 'testing',
            type,
          });
        });
      });
    });
  });

  describe('rename entry', () => {
    beforeEach(() => {
      const store = createStore();
      store.state.entryModal = {
        type: 'rename',
        path: '',
        entry: {
          name: 'test',
          type: 'blob',
          path: 'test-path',
        },
      };

      vm = createComponentWithStore(Component, store).$mount();
    });

    ['tree', 'blob'].forEach(type => {
      it(`renders title and button for renaming ${type}`, done => {
        const text = type === 'tree' ? 'folder' : 'file';

        vm.$store.state.entryModal.entry.type = type;

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.modal-title').textContent.trim()).toBe(`Rename ${text}`);
          expect(vm.$el.querySelector('.btn-success').textContent.trim()).toBe(`Rename ${text}`);

          done();
        });
      });
    });

    describe('entryName', () => {
      it('returns entries name', () => {
        expect(vm.entryName).toBe('test-path');
      });

      it('updated name', () => {
        vm.name = 'index.js';

        expect(vm.entryName).toBe('index.js');
      });

      it('removes leading/trailing spaces when found in the new name', () => {
        vm.entryName = ' index.js ';

        expect(vm.entryName).toBe('index.js');
      });

      it('does not remove internal spaces in the file name', () => {
        vm.entryName = ' In Praise of Idleness.txt ';

        expect(vm.entryName).toBe('In Praise of Idleness.txt');
      });
    });
  });

  describe('submitForm', () => {
    it('throws an error when target entry exists', () => {
      const store = createStore();
      store.state.entryModal = {
        type: 'rename',
        path: 'test-path/test',
        entry: {
          name: 'test',
          type: 'blob',
          path: 'test-path/test',
        },
      };
      store.state.entries = {
        'test-path/test': {
          name: 'test',
          deleted: false,
        },
      };

      vm = createComponentWithStore(Component, store).$mount();
      const flashSpy = spyOnDependency(modal, 'flash');
      vm.submitForm();

      expect(flashSpy).toHaveBeenCalled();
    });

    it('calls createTempEntry when target path does not exist', () => {
      const store = createStore();
      store.state.entryModal = {
        type: 'rename',
        path: 'test-path/test',
        entry: {
          name: 'test',
          type: 'blob',
          path: 'test-path1/test',
        },
      };

      vm = createComponentWithStore(Component, store).$mount();
      spyOn(vm, 'createTempEntry').and.callFake(() => Promise.resolve());
      vm.submitForm();

      expect(vm.createTempEntry).toHaveBeenCalledWith({
        name: 'test-path1',
        type: 'tree',
      });
    });
  });
});
