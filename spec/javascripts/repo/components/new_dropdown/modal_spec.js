import Vue from 'vue';
import RepoStore from '~/repo/stores/repo_store';
import RepoHelper from '~/repo/helpers/repo_helper';
import modal from '~/repo/components/new_dropdown/modal.vue';
import createComponent from '../../../helpers/vue_mount_component_helper';

describe('new file modal component', () => {
  const Component = Vue.extend(modal);
  let vm;

  afterEach(() => {
    vm.$destroy();

    RepoStore.files = [];
    RepoStore.openedFiles = [];
    RepoStore.setViewToPreview();
  });

  ['tree', 'blob'].forEach((type) => {
    describe(type, () => {
      beforeEach(() => {
        vm = createComponent(Component, {
          type,
        });
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

      it('emits toggle event after creating file', () => {
        spyOn(vm, '$emit');

        vm.entryName = 'testing';
        vm.$el.querySelector('.btn-success').click();

        expect(vm.$emit).toHaveBeenCalledWith('toggle');
      });

      it('sets editMode to true', () => {
        vm.entryName = 'testing';
        vm.$el.querySelector('.btn-success').click();

        expect(RepoStore.editMode).toBeTruthy();
      });

      it('toggles blob view', () => {
        vm.entryName = 'testing';
        vm.$el.querySelector('.btn-success').click();

        expect(RepoStore.isPreviewView()).toBeFalsy();
      });

      it('adds file into activeFiles', () => {
        vm.entryName = 'testing';
        vm.$el.querySelector('.btn-success').click();

        expect(RepoStore.openedFiles.length).toBe(1);
      });

      it(`creates ${type} in the current stores path`, () => {
        RepoStore.path = 'testing';
        vm.entryName = 'testing/app';

        vm.$el.querySelector('.btn-success').click();

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
    beforeEach(() => {
      vm = createComponent(Component, {
        type: 'blob',
      });
    });

    it('creates new file', () => {
      vm.entryName = 'testing';
      vm.$el.querySelector('.btn-success').click();

      expect(RepoStore.files.length).toBe(1);
      expect(RepoStore.files[0].name).toBe('testing');
      expect(RepoStore.files[0].type).toBe('blob');
      expect(RepoStore.files[0].tempFile).toBeTruthy();
    });

    it('does not create temp file when file already exists', () => {
      RepoStore.files.push(RepoHelper.serializeRepoEntity('blob', {
        name: 'testing',
      }));

      vm.entryName = 'testing';
      vm.$el.querySelector('.btn-success').click();

      expect(RepoStore.files.length).toBe(1);
      expect(RepoStore.files[0].name).toBe('testing');
      expect(RepoStore.files[0].type).toBe('blob');
      expect(RepoStore.files[0].tempFile).toBeUndefined();
    });
  });

  describe('tree', () => {
    beforeEach(() => {
      vm = createComponent(Component, {
        type: 'tree',
      });
    });

    it('creates new tree', () => {
      vm.entryName = 'testing';
      vm.$el.querySelector('.btn-success').click();

      expect(RepoStore.files.length).toBe(1);
      expect(RepoStore.files[0].name).toBe('testing');
      expect(RepoStore.files[0].type).toBe('tree');
      expect(RepoStore.files[0].tempFile).toBeTruthy();
      expect(RepoStore.files[0].files.length).toBe(1);
      expect(RepoStore.files[0].files[0].name).toBe('.gitkeep');
    });

    it('creates multiple trees when entryName has slashes', () => {
      vm.entryName = 'app/test';
      vm.$el.querySelector('.btn-success').click();

      expect(RepoStore.files.length).toBe(1);
      expect(RepoStore.files[0].name).toBe('app');
      expect(RepoStore.files[0].files[0].name).toBe('test');
      expect(RepoStore.files[0].files[0].files[0].name).toBe('.gitkeep');
    });

    it('creates tree in existing tree', () => {
      RepoStore.files.push(RepoHelper.serializeRepoEntity('tree', {
        name: 'app',
      }));

      vm.entryName = 'app/test';
      vm.$el.querySelector('.btn-success').click();

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

      vm.entryName = 'app';
      vm.$el.querySelector('.btn-success').click();

      expect(RepoStore.files.length).toBe(1);
      expect(RepoStore.files[0].name).toBe('app');
      expect(RepoStore.files[0].tempFile).toBeUndefined();
      expect(RepoStore.files[0].files.length).toBe(0);
    });
  });

  it('focuses field on mount', () => {
    document.body.innerHTML += '<div class="js-test"></div>';

    vm = createComponent(Component, {
      type: 'tree',
    }, '.js-test');

    expect(document.activeElement).toBe(vm.$refs.fieldName);

    vm.$el.remove();
  });
});
