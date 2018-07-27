import Vue from 'vue';
import { createStore } from '~/ide/stores';
import modal from '~/ide/components/new_dropdown/modal.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

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
        store.state.newEntryModal = {
          type,
          path: '',
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

      describe('createEntryInStore', () => {
        it('$emits create', () => {
          spyOn(vm, 'createTempEntry');

          vm.createEntryInStore();

          expect(vm.createTempEntry).toHaveBeenCalledWith({
            name: 'testing',
            type,
          });
        });
      });
    });
  });
});
