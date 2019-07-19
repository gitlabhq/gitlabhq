import Vue from 'vue';
import tableRegistry from '~/registry/components/table_registry.vue';
import store from '~/registry/stores';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { repoPropsData } from '../mock_data';

const [firstImage, secondImage] = repoPropsData.list;

describe('table registry', () => {
  let vm;
  const Component = Vue.extend(tableRegistry);
  const bulkDeletePath = 'path';

  const findDeleteBtn = () => vm.$el.querySelector('.js-delete-registry');
  const findDeleteBtnRow = () => vm.$el.querySelector('.js-delete-registry-row');
  const findSelectAllCheckbox = () => vm.$el.querySelector('.js-select-all-checkbox > input');
  const findAllRowCheckboxes = () =>
    Array.from(vm.$el.querySelectorAll('.js-select-checkbox input'));
  const confirmationModal = (child = '') => document.querySelector(`#${vm.modalId} ${child}`);

  const createComponent = () => {
    vm = mountComponentWithStore(Component, {
      store,
      props: {
        repo: repoPropsData,
      },
    });
  };

  const selectAllCheckboxes = () => vm.selectAll();
  const deselectAllCheckboxes = () => vm.deselectAll();

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('rendering', () => {
    it('should render a table with the registry list', () => {
      expect(vm.$el.querySelectorAll('table tbody tr').length).toEqual(repoPropsData.list.length);
    });

    it('should render registry tag', () => {
      const textRendered = vm.$el
        .querySelector('.table tbody tr')
        .textContent.trim()
        .replace(/\s\s+/g, ' ');

      expect(textRendered).toContain(repoPropsData.list[0].tag);
      expect(textRendered).toContain(repoPropsData.list[0].shortRevision);
      expect(textRendered).toContain(repoPropsData.list[0].layers);
      expect(textRendered).toContain(repoPropsData.list[0].size);
    });
  });

  describe('multi select', () => {
    it('should support multiselect and selecting a row should enable delete button', done => {
      findSelectAllCheckbox().click();
      selectAllCheckboxes();

      expect(findSelectAllCheckbox().checked).toBe(true);

      Vue.nextTick(() => {
        expect(findDeleteBtn().disabled).toBe(false);
        done();
      });
    });

    it('selecting all checkbox should select all rows and enable delete button', done => {
      selectAllCheckboxes();

      Vue.nextTick(() => {
        const checkedValues = findAllRowCheckboxes().filter(x => x.checked);

        expect(checkedValues.length).toBe(repoPropsData.list.length);
        done();
      });
    });

    it('deselecting select all checkbox should deselect all rows and disable delete button', done => {
      selectAllCheckboxes();
      deselectAllCheckboxes();

      Vue.nextTick(() => {
        const checkedValues = findAllRowCheckboxes().filter(x => x.checked);

        expect(checkedValues.length).toBe(0);
        done();
      });
    });

    it('should delete multiple items when multiple items are selected', done => {
      selectAllCheckboxes();

      Vue.nextTick(() => {
        expect(vm.itemsToBeDeleted).toEqual([0, 1]);
        expect(findDeleteBtn().disabled).toBe(false);

        findDeleteBtn().click();
        spyOn(vm, 'deleteItems').and.returnValue(Promise.resolve());

        Vue.nextTick(() => {
          const modal = confirmationModal();
          confirmationModal('.btn-danger').click();

          expect(modal).toExist();

          Vue.nextTick(() => {
            expect(vm.itemsToBeDeleted).toEqual([]);
            expect(vm.deleteItems).toHaveBeenCalledWith({
              path: bulkDeletePath,
              items: [firstImage.tag, secondImage.tag],
            });
            done();
          });
        });
      });
    });
  });

  describe('delete registry', () => {
    beforeEach(() => {
      vm.itemsToBeDeleted = [0];
    });

    it('should be possible to delete a registry', done => {
      Vue.nextTick(() => {
        expect(vm.itemsToBeDeleted).toEqual([0]);
        expect(findDeleteBtn()).toBeDefined();
        expect(findDeleteBtn().disabled).toBe(false);
        expect(findDeleteBtnRow()).toBeDefined();
        done();
      });
    });

    it('should call deleteItems and reset itemsToBeDeleted when confirming deletion', done => {
      Vue.nextTick(() => {
        expect(vm.itemsToBeDeleted).toEqual([0]);
        expect(findDeleteBtn().disabled).toBe(false);
        findDeleteBtn().click();
        spyOn(vm, 'deleteItems').and.returnValue(Promise.resolve());

        Vue.nextTick(() => {
          confirmationModal('.btn-danger').click();

          expect(vm.itemsToBeDeleted).toEqual([]);
          expect(vm.deleteItems).toHaveBeenCalledWith({
            path: bulkDeletePath,
            items: [firstImage.tag],
          });
          done();
        });
      });
    });
  });

  describe('pagination', () => {
    it('should be possible to change the page', () => {
      expect(vm.$el.querySelector('.gl-pagination')).toBeDefined();
    });
  });

  describe('modal content', () => {
    it('should show the singular title and image name when deleting a single image', done => {
      findDeleteBtnRow().click();

      Vue.nextTick(() => {
        expect(vm.modalTitle).toBe('Remove image');
        expect(vm.modalDescription).toContain(firstImage.tag);
        done();
      });
    });

    it('should show the plural title and image count when deleting more than one image', done => {
      selectAllCheckboxes();

      Vue.nextTick(() => {
        expect(vm.modalTitle).toBe('Remove images');
        expect(vm.modalDescription).toContain('<b>2</b> images');
        done();
      });
    });
  });
});
