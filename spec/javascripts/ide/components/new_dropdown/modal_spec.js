import Vue from 'vue';
import modal from '~/ide/components/new_dropdown/modal.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('new file modal component', () => {
  const Component = Vue.extend(modal);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  ['tree', 'blob'].forEach(type => {
    describe(type, () => {
      beforeEach(() => {
        vm = createComponent(Component, {
          type,
          branchId: 'master',
          path: '',
        });

        vm.entryName = 'testing';
      });

      it(`sets modal title as ${type}`, () => {
        const title = type === 'tree' ? 'directory' : 'file';

        expect(vm.$el.querySelector('.modal-title').textContent.trim()).toBe(
          `Create new ${title}`,
        );
      });

      it(`sets button label as ${type}`, () => {
        const title = type === 'tree' ? 'directory' : 'file';

        expect(vm.$el.querySelector('.btn-success').textContent.trim()).toBe(
          `Create ${title}`,
        );
      });

      it(`sets form label as ${type}`, () => {
        const title = type === 'tree' ? 'Directory' : 'File';

        expect(vm.$el.querySelector('.label-light').textContent.trim()).toBe(
          `${title} name`,
        );
      });

      describe('createEntryInStore', () => {
        it('$emits create', () => {
          spyOn(vm, '$emit');

          vm.createEntryInStore();

          expect(vm.$emit).toHaveBeenCalledWith('create', {
            branchId: 'master',
            name: 'testing',
            type,
          });
        });
      });
    });
  });

  it('focuses field on mount', () => {
    document.body.innerHTML += '<div class="js-test"></div>';

    vm = createComponent(
      Component,
      {
        type: 'tree',
        branchId: 'master',
        path: '',
      },
      '.js-test',
    );

    expect(document.activeElement).toBe(vm.$refs.fieldName);

    vm.$el.remove();
  });
});
