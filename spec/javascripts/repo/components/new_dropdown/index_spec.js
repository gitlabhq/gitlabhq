import Vue from 'vue';
import store from '~/repo/stores';
import newDropdown from '~/repo/components/new_dropdown/index.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store);

    vm.$store.state.path = '';

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders new file and new directory links', () => {
    expect(vm.$el.querySelectorAll('a')[0].textContent.trim()).toBe('New file');
    expect(vm.$el.querySelectorAll('a')[1].textContent.trim()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('sets modalType to blob when new file is clicked', () => {
      vm.$el.querySelectorAll('a')[0].click();

      expect(vm.modalType).toBe('blob');
    });

    it('sets modalType to tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('a')[1].click();

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

  describe('toggleModalOpen', () => {
    it('closes modal after toggling', (done) => {
      vm.toggleModalOpen();

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.modal')).not.toBeNull();
        })
        .then(vm.toggleModalOpen)
        .then(() => {
          expect(vm.$el.querySelector('.modal')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
<<<<<<< HEAD

  describe('createEntryInStore', () => {
    ['tree', 'blob'].forEach((type) => {
      describe(type, () => {
        it('closes modal after creating file', () => {
          vm.openModal = true;

          eventHub.$emit('createNewEntry', {
            name: 'testing',
            type,
            toggleModal: true,
          });

          expect(vm.openModal).toBeFalsy();
        });

        it('sets editMode to true', () => {
          eventHub.$emit('createNewEntry', {
            name: 'testing',
            type,
          });

          expect(RepoStore.editMode).toBeTruthy();
        });

        it('toggles blob view', () => {
          eventHub.$emit('createNewEntry', {
            name: 'testing',
            type,
          });

          expect(RepoStore.isPreviewView()).toBeFalsy();
        });

        it('adds file into activeFiles', () => {
          eventHub.$emit('createNewEntry', {
            name: 'testing',
            type,
          });

          expect(RepoStore.openedFiles.length).toBe(1);
        });

        it(`creates ${type} in the current stores path`, () => {
          RepoStore.path = 'testing';

          eventHub.$emit('createNewEntry', {
            name: 'testing/app',
            type,
          });

          expect(RepoStore.files[0].path).toBe('testing/app');
          expect(RepoStore.files[0].name).toBe('app');

          if (type === 'tree') {
            expect(RepoStore.files[0].files.length).toBe(1);
          }

          RepoStore.path = '';
        });
      });
    });

    describe('file', () => {
      it('creates new file', () => {
        eventHub.$emit('createNewEntry', {
          name: 'testing',
          type: 'blob',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('testing');
        expect(RepoStore.files[0].type).toBe('blob');
        expect(RepoStore.files[0].tempFile).toBeTruthy();
      });

      it('does not create temp file when file already exists', () => {
        RepoStore.files.push(RepoHelper.serializeRepoEntity('blob', {
          name: 'testing',
        }));

        eventHub.$emit('createNewEntry', {
          name: 'testing',
          type: 'blob',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('testing');
        expect(RepoStore.files[0].type).toBe('blob');
        expect(RepoStore.files[0].tempFile).toBeUndefined();
      });
    });

    describe('tree', () => {
      it('creates new tree', () => {
        eventHub.$emit('createNewEntry', {
          name: 'testing',
          type: 'tree',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('testing');
        expect(RepoStore.files[0].type).toBe('tree');
        expect(RepoStore.files[0].tempFile).toBeTruthy();
        expect(RepoStore.files[0].files.length).toBe(1);
        expect(RepoStore.files[0].files[0].name).toBe('.gitkeep');
      });

      it('creates multiple trees when entryName has slashes', () => {
        eventHub.$emit('createNewEntry', {
          name: 'app/test',
          type: 'tree',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('app');
        expect(RepoStore.files[0].files[0].name).toBe('test');
        expect(RepoStore.files[0].files[0].files[0].name).toBe('.gitkeep');
      });

      it('creates tree in existing tree', () => {
        RepoStore.files.push(RepoHelper.serializeRepoEntity('tree', {
          name: 'app',
        }));

        eventHub.$emit('createNewEntry', {
          name: 'app/test',
          type: 'tree',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('app');
        expect(RepoStore.files[0].tempFile).toBeUndefined();
        expect(RepoStore.files[0].files[0].tempFile).toBeTruthy();
        expect(RepoStore.files[0].files[0].name).toBe('test');
        expect(RepoStore.files[0].files[0].files[0].name).toBe('.gitkeep');
      });

      it('does not create new tree when already exists', () => {
        RepoStore.files.push(RepoHelper.serializeRepoEntity('tree', {
          name: 'app',
        }));

        eventHub.$emit('createNewEntry', {
          name: 'app',
          type: 'tree',
        });

        expect(RepoStore.files.length).toBe(1);
        expect(RepoStore.files[0].name).toBe('app');
        expect(RepoStore.files[0].tempFile).toBeUndefined();
        expect(RepoStore.files[0].files.length).toBe(0);
      });
    });
  });
=======
>>>>>>> e24d1890aea9c550e02d9145f50e8e1ae153a3a3
});
