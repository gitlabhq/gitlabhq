import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import TableHeaderComponent from 'ee/group_member_contributions/components/table_header.vue';
import defaultColumns from 'ee/group_member_contributions/constants';

import { mockSortOrders } from '../mock_data';

const createComponent = (columns = defaultColumns, sortOrders = mockSortOrders) => {
  const Component = Vue.extend(TableHeaderComponent);

  return mountComponent(Component, { columns, sortOrders });
};

describe('TableHeaderComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns data with columnIconMeta prop initialized', () => {
      defaultColumns.forEach(column => {
        expect(vm.columnIconMeta[column.name].sortIcon).toBe('angle-up');
        expect(vm.columnIconMeta[column.name].iconTooltip).toBe('Ascending');
      });
    });
  });

  describe('methods', () => {
    const columnName = 'fullname';

    describe('getColumnIconMeta', () => {
      it('returns `angle-up` and `Ascending` for sortIcon and iconTooltip respectively when provided columnName in sortOrders has value greater than 0', () => {
        const iconMeta = vm.getColumnIconMeta(columnName, { fullname: 1 });
        expect(iconMeta.sortIcon).toBe('angle-up');
        expect(iconMeta.iconTooltip).toBe('Ascending');
      });

      it('returns `angle-down` and `Descending` for sortIcon and iconTooltip respectively when provided columnName in sortOrders has value less than 0', () => {
        const iconMeta = vm.getColumnIconMeta(columnName, { fullname: -1 });
        expect(iconMeta.sortIcon).toBe('angle-down');
        expect(iconMeta.iconTooltip).toBe('Descending');
      });
    });

    describe('getColumnSortIcon', () => {
      it('returns value of sortIcon for provided columnName', () => {
        expect(vm.getColumnSortIcon(columnName)).toBe('angle-up');
      });
    });

    describe('getColumnSortTooltip', () => {
      it('returns value of iconTooltip for provided columnName', () => {
        expect(vm.getColumnSortTooltip(columnName)).toBe('Ascending');
      });
    });

    describe('onColumnClick', () => {
      it('emits `onColumnClick` event with columnName param on component instance', () => {
        spyOn(vm, '$emit');
        vm.onColumnClick(columnName);
        expect(vm.$emit).toHaveBeenCalledWith('onColumnClick', columnName);
      });

      it('updates columnIconMeta prop for provided columnName', () => {
        spyOn(vm, 'getColumnIconMeta');
        vm.onColumnClick(columnName);
        expect(vm.getColumnIconMeta).toHaveBeenCalledWith(columnName, vm.sortOrders);
      });
    });
  });

  describe('template', () => {
    it('renders table column header with sort order icon', () => {
      const headerItemEl = vm.$el.querySelector('tr th');
      expect(headerItemEl).not.toBeNull();
      expect(headerItemEl.innerText.trim()).toBe('Name');
      expect(headerItemEl.querySelector('svg use').getAttribute('xlink:href')).toContain(
        'angle-up',
      );
    });
  });
});
