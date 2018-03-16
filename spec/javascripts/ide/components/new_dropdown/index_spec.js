import Vue from 'vue';
import store from 'ee/ide/stores';
import newDropdown from 'ee/ide/components/new_dropdown/index.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store, {
      branch: 'master',
      path: '',
    });

    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.path = '';
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders new file, upload and new directory links', () => {
    expect(vm.$el.querySelectorAll('a')[0].textContent.trim()).toBe('New file');
    expect(vm.$el.querySelectorAll('a')[1].textContent.trim()).toBe('Upload file');
    expect(vm.$el.querySelectorAll('a')[2].textContent.trim()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('sets modalType to blob when new file is clicked', () => {
      vm.$el.querySelectorAll('a')[0].click();

      expect(vm.modalType).toBe('blob');
    });

    it('sets modalType to tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('a')[2].click();

      expect(vm.modalType).toBe('tree');
    });

    it('opens modal when link is clicked', (done) => {
      vm.$el.querySelectorAll('a')[0].click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.modal')).not.toBeNull();

        done();
      });
    });
  });

  describe('hideModal', () => {
    beforeAll((done) => {
      vm.openModal = true;
      Vue.nextTick(done);
    });

    it('closes modal after toggling', (done) => {
      vm.hideModal();

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.modal')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  // TODO: move all this to the action spec
  describe('createTempEntry', () => {
    ['tree', 'blob'].forEach((type) => {
      if (type === 'blob') {
        it('creates new file', (done) => {
          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'testing',
            type,
          }).then(() => {
            const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('testing');
            expect(baseTree[0].type).toBe('blob');
            expect(baseTree[0].tempFile).toBeTruthy();

            done();
          })
          .catch(done.fail);
        });

        it('does not create temp file when file already exists', (done) => {
          const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
          baseTree.push(file('testing', '1', type));

          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'testing',
            type,
          })
            .then(() => {
              expect(baseTree.length).toBe(1);
              expect(baseTree[0].name).toBe('testing');
              expect(baseTree[0].type).toBe('blob');
              expect(baseTree[0].tempFile).toBeFalsy();

              done();
            })
            .catch(done.fail);
        });
      } else {
        it('creates new tree', (done) => {
          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'testing',
            type,
          })
            .then(() => {
              const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
              expect(baseTree.length).toBe(1);
              expect(baseTree[0].name).toBe('testing');
              expect(baseTree[0].type).toBe('tree');
              expect(baseTree[0].tempFile).toBeTruthy();

              done();
            })
            .catch(done.fail);
        });

        it('creates multiple trees when entryName has slashes', (done) => {
          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'app/test',
            type,
          })
            .then(() => {
              const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
              expect(baseTree.length).toBe(1);
              expect(baseTree[0].name).toBe('app');

              done();
            })
            .catch(done.fail);
        });

        it('creates tree in existing tree', (done) => {
          const f = file('app', '1', 'tree');
          const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
          baseTree.push(f);
          vm.$store.state.entries[f.path] = f;

          vm.entryName = 'app/test';
          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'app/test',
            type,
          }).then(() => {
            expect(baseTree.length).toBe(1);
            // console.log(baseTree[0].tree);
            expect(baseTree[0].name).toBe('app');
            expect(baseTree[0].tempFile).toBeFalsy();
            expect(baseTree[0].tree[0].tempFile).toBeTruthy();
            expect(baseTree[0].tree[0].name).toBe('test');

            done();
          }).catch(done.fail);
        });

        it('does not create new tree when already exists', (done) => {
          const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
          baseTree.push(file('app', '1', 'tree'));

          vm.createTempEntry({
            branchId: 'mybranch',
            name: 'app',
            type,
          }).then(() => {
            expect(baseTree.length).toBe(1);
            expect(baseTree[0].name).toBe('app');
            expect(baseTree[0].tempFile).toBeFalsy();
            expect(baseTree[0].tree.length).toBe(0);

            done();
          }).catch(done.fail);
        });
      }
    });
  });
});
