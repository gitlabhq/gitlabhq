import Vue from 'vue';
import store from '~/repo/stores';
import modal from '~/repo/components/new_dropdown/modal.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('new file modal component', () => {
  const Component = Vue.extend(modal);
  let vm;

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  ['tree', 'blob'].forEach((type) => {
    describe(type, () => {
      beforeEach(() => {
        vm = createComponentWithStore(Component, store, {
          type,
          path: '',
        }).$mount();

        vm.entryName = 'testing';
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
        const title = type === 'tree' ? 'Directory' : 'File';

        expect(vm.$el.querySelector('.label-light').textContent.trim()).toBe(`${title} name`);
      });

      describe('createEntryInStore', () => {
        it('calls createTempEntry', () => {
          spyOn(vm, 'createTempEntry');

          vm.createEntryInStore();

          expect(vm.createTempEntry).toHaveBeenCalledWith({
            name: 'testing',
            type,
          });
        });

        it('sets editMode to true', (done) => {
          vm.createEntryInStore();

          setTimeout(() => {
            expect(vm.$store.state.editMode).toBeTruthy();

            done();
          });
        });

        it('toggles blob view', (done) => {
          vm.createEntryInStore();

          setTimeout(() => {
            expect(vm.$store.state.currentBlobView).toBe('repo-editor');

            done();
          });
        });

        it('opens newly created file', (done) => {
          vm.createEntryInStore();

          setTimeout(() => {
            expect(vm.$store.state.openFiles.length).toBe(1);
            expect(vm.$store.state.openFiles[0].name).toBe(type === 'blob' ? 'testing' : '.gitkeep');

            done();
          });
        });

        it(`creates ${type} in the current stores path`, (done) => {
          vm.$store.state.path = 'app';

          vm.createEntryInStore();

          setTimeout(() => {
            expect(vm.$store.state.tree[0].path).toBe('app/testing');
            expect(vm.$store.state.tree[0].name).toBe('testing');

            if (type === 'tree') {
              expect(vm.$store.state.tree[0].tree.length).toBe(1);
            }

            done();
          });
        });

        if (type === 'blob') {
          it('creates new file', (done) => {
            vm.createEntryInStore();

            setTimeout(() => {
              expect(vm.$store.state.tree.length).toBe(1);
              expect(vm.$store.state.tree[0].name).toBe('testing');
              expect(vm.$store.state.tree[0].type).toBe('blob');
              expect(vm.$store.state.tree[0].tempFile).toBeTruthy();

              done();
            });
          });

          it('does not create temp file when file already exists', (done) => {
            vm.$store.state.tree.push(file('testing', '1', type));

            vm.createEntryInStore();

            setTimeout(() => {
              expect(vm.$store.state.tree.length).toBe(1);
              expect(vm.$store.state.tree[0].name).toBe('testing');
              expect(vm.$store.state.tree[0].type).toBe('blob');
              expect(vm.$store.state.tree[0].tempFile).toBeFalsy();

              done();
            });
          });
        } else {
          it('creates new tree', () => {
            vm.createEntryInStore();

            expect(vm.$store.state.tree.length).toBe(1);
            expect(vm.$store.state.tree[0].name).toBe('testing');
            expect(vm.$store.state.tree[0].type).toBe('tree');
            expect(vm.$store.state.tree[0].tempFile).toBeTruthy();
            expect(vm.$store.state.tree[0].tree.length).toBe(1);
            expect(vm.$store.state.tree[0].tree[0].name).toBe('.gitkeep');
          });

          it('creates multiple trees when entryName has slashes', () => {
            vm.entryName = 'app/test';
            vm.createEntryInStore();

            expect(vm.$store.state.tree.length).toBe(1);
            expect(vm.$store.state.tree[0].name).toBe('app');
            expect(vm.$store.state.tree[0].tree[0].name).toBe('test');
            expect(vm.$store.state.tree[0].tree[0].tree[0].name).toBe('.gitkeep');
          });

          it('creates tree in existing tree', () => {
            vm.$store.state.tree.push(file('app', '1', 'tree'));

            vm.entryName = 'app/test';
            vm.createEntryInStore();

            expect(vm.$store.state.tree.length).toBe(1);
            expect(vm.$store.state.tree[0].name).toBe('app');
            expect(vm.$store.state.tree[0].tempFile).toBeFalsy();
            expect(vm.$store.state.tree[0].tree[0].tempFile).toBeTruthy();
            expect(vm.$store.state.tree[0].tree[0].name).toBe('test');
            expect(vm.$store.state.tree[0].tree[0].tree[0].name).toBe('.gitkeep');
          });

          it('does not create new tree when already exists', () => {
            vm.$store.state.tree.push(file('app', '1', 'tree'));

            vm.entryName = 'app';
            vm.createEntryInStore();

            expect(vm.$store.state.tree.length).toBe(1);
            expect(vm.$store.state.tree[0].name).toBe('app');
            expect(vm.$store.state.tree[0].tempFile).toBeFalsy();
            expect(vm.$store.state.tree[0].tree.length).toBe(0);
          });
        }
      });
    });
  });

  it('focuses field on mount', () => {
    document.body.innerHTML += '<div class="js-test"></div>';

    vm = createComponentWithStore(Component, store, {
      type: 'tree',
      path: '',
    }).$mount('.js-test');

    expect(document.activeElement).toBe(vm.$refs.fieldName);

    vm.$el.remove();
  });
});
