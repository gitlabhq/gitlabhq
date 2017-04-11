import Vue from 'vue';
import table from '~/blob/xlsx/components/table.vue';

describe('XLSX table', () => {
  let vm;

  beforeEach((done) => {
    const TableComponent = Vue.extend(table);

    vm = new TableComponent({
      propsData: {
        sheet: {},
      },
    }).$mount();

    Vue.nextTick(done);
  });

  describe('linePath', () => {
    it('returns linePath with just the number when hash is empty', () => {
      expect(
        vm.linePath(0),
      ).toBe('#L1');
    });

    it('returns linePath with just the number when hash has a value', () => {
      location.hash = 'test';

      expect(
        vm.linePath(0),
      ).toBe('#test-L1');
    });
  });

  describe('getCurrentLineNumberFromUrl', () => {
    it('gets line number', () => {
      location.hash = 'L1';
      vm.getCurrentLineNumberFromUrl();

      expect(
        vm.currentLineNumber,
      ).toBe(1);
    });

    it('gets line number when hash has sheet name', () => {
      location.hash = 'test-L1';
      vm.getCurrentLineNumberFromUrl();

      expect(
        vm.currentLineNumber,
      ).toBe(1);
    });
  });
});
