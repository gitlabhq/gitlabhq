import Vue from 'vue';
import tableRegistry from '~/registry/components/table_registry.vue';
import store from '~/registry/stores';
import { repoPropsData } from '../mock_data';

const [firstImage] = repoPropsData.list;

describe('table registry', () => {
  let vm;
  let Component;

  const findDeleteBtn = () => vm.$el.querySelector('.js-delete-registry');

  beforeEach(() => {
    Component = Vue.extend(tableRegistry);
    vm = new Component({
      store,
      propsData: {
        repo: repoPropsData,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

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

  describe('delete registry', () => {
    it('should be possible to delete a registry', () => {
      expect(findDeleteBtn()).toBeDefined();
    });

    describe('clicked on delete', () => {
      beforeEach(done => {
        findDeleteBtn().click();
        Vue.nextTick(done);
      });

      it('should open confirmation modal and set itemToBeDeleted properly', () => {
        expect(vm.itemToBeDeleted).toEqual(firstImage);
        expect(vm.$el.querySelector('#confirm-image-deletion-modal')).not.toBeNull();
      });

      it('should call deleteItem and reset itemToBeDeleted when confirming deletion', () => {
        spyOn(vm, 'deleteItem').and.returnValue(Promise.resolve());
        vm.$el.querySelector('#confirm-image-deletion-modal .btn-danger').click();

        expect(vm.deleteItem).toHaveBeenCalledWith(firstImage);
        expect(vm.itemToBeDeleted).toBeNull();
      });
    });
  });

  describe('pagination', () => {
    it('should be possible to change the page', () => {
      expect(vm.$el.querySelector('.gl-pagination')).toBeDefined();
    });
  });
});
