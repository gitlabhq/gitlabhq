import Vue from 'vue';
import store from '~/ide/stores';
import service from '~/ide/services';
import modal from '~/ide/components/new_dropdown/modal.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('new file modal component', () => {
  const Component = Vue.extend(modal);
  let vm;
  let projectTree;

  beforeEach(() => {
    spyOn(service, 'getProjectData').and.returnValue(Promise.resolve({
      data: {
        id: '123',
      },
    }));

    spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
      data: {
        commit: {
          id: '123branch',
        },
      },
    }));

    spyOn(service, 'getTreeData').and.returnValue(Promise.resolve({
      headers: {
        'page-title': 'test',
      },
      json: () => Promise.resolve({
        last_commit_path: 'last_commit_path',
        parent_tree_url: 'parent_tree_url',
        path: '/',
        trees: [{ name: 'tree' }],
        blobs: [{ name: 'blob' }],
        submodules: [{ name: 'submodule' }],
      }),
    }));
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  ['tree', 'blob'].forEach((type) => {
    describe(type, () => {
      beforeEach(() => {
        store.state.projects.abcproject = {
          web_url: '',
        };
        store.state.trees = [];
        store.state.trees['abcproject/mybranch'] = {
          tree: [],
        };
        projectTree = store.state.trees['abcproject/mybranch'];
        store.state.currentProjectId = 'abcproject';

        vm = createComponentWithStore(Component, store, {
          type,
          branchId: 'master',
          path: '',
          parent: projectTree,
        });

        vm.entryName = 'testing';

        vm.$mount();
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
            projectId: 'abcproject',
            branchId: 'master',
            parent: projectTree,
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
          if (type === 'blob') {
            vm.createEntryInStore();

            setTimeout(() => {
              expect(vm.$store.state.openFiles.length).toBe(1);
              expect(vm.$store.state.openFiles[0].name).toBe(type === 'blob' ? 'testing' : '.gitkeep');

              done();
            });
          } else {
            done();
          }
        });

        if (type === 'blob') {
          it('creates new file', (done) => {
            vm.createEntryInStore();

            setTimeout(() => {
              const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
              expect(baseTree.length).toBe(1);
              expect(baseTree[0].name).toBe('testing');
              expect(baseTree[0].type).toBe('blob');
              expect(baseTree[0].tempFile).toBeTruthy();

              done();
            });
          });

          it('does not create temp file when file already exists', (done) => {
            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            baseTree.push(file('testing', '1', type));

            vm.createEntryInStore();

            setTimeout(() => {
              expect(baseTree.length).toBe(1);
              expect(baseTree[0].name).toBe('testing');
              expect(baseTree[0].type).toBe('blob');
              expect(baseTree[0].tempFile).toBeFalsy();

              done();
            });
          });
        } else {
          it('creates new tree', () => {
            vm.createEntryInStore();

            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('testing');
            expect(baseTree[0].type).toBe('tree');
            expect(baseTree[0].tempFile).toBeTruthy();
          });

          it('creates multiple trees when entryName has slashes', () => {
            vm.entryName = 'app/test';
            vm.createEntryInStore();

            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('app');
          });

          it('creates tree in existing tree', () => {
            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            baseTree.push(file('app', '1', 'tree'));

            vm.entryName = 'app/test';
            vm.createEntryInStore();

            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('app');
            expect(baseTree[0].tempFile).toBeFalsy();
            expect(baseTree[0].tree[0].tempFile).toBeTruthy();
            expect(baseTree[0].tree[0].name).toBe('test');
          });

          it('does not create new tree when already exists', () => {
            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            baseTree.push(file('app', '1', 'tree'));

            vm.entryName = 'app';
            vm.createEntryInStore();

            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('app');
            expect(baseTree[0].tempFile).toBeFalsy();
            expect(baseTree[0].tree.length).toBe(0);
          });
        }
      });
    });
  });

  it('focuses field on mount', () => {
    document.body.innerHTML += '<div class="js-test"></div>';

    vm = createComponentWithStore(Component, store, {
      type: 'tree',
      projectId: 'abcproject',
      branchId: 'master',
      path: '',
    }).$mount('.js-test');

    expect(document.activeElement).toBe(vm.$refs.fieldName);

    vm.$el.remove();
  });
});
