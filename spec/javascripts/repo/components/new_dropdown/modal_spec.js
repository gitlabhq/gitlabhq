import Vue from 'vue';
import RepoStore from '~/repo/stores/repo_store';
import modal from '~/repo/components/new_dropdown/modal.vue';
import eventHub from '~/repo/event_hub';
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
          currentPath: RepoStore.path,
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
    });
  });

  it('focuses field on mount', () => {
    document.body.innerHTML += '<div class="js-test"></div>';

    vm = createComponent(Component, {
      type: 'tree',
      currentPath: RepoStore.path,
    }, '.js-test');

    expect(document.activeElement).toBe(vm.$refs.fieldName);

    vm.$el.remove();
  });

  describe('createEntryInStore', () => {
    it('emits createNewEntry event', () => {
      spyOn(eventHub, '$emit');

      vm = createComponent(Component, {
        type: 'tree',
        currentPath: RepoStore.path,
      });
      vm.entryName = 'testing';

      vm.createEntryInStore();

      expect(eventHub.$emit).toHaveBeenCalledWith('createNewEntry', {
        name: 'testing',
        type: 'tree',
        toggleModal: true,
      });
    });
  });
});
