import Vue from 'vue';
import table from '~/blob/xlsx/components/table.vue';

describe('XLSX table', () => {
  let vm;

  beforeEach((done) => {
    const TableComponent = Vue.extend(table);

    vm = new TableComponent({
      propsData: {
        sheet: {
          columns: ['test', 'test 2'],
          rows: [
            ['test 3', 'test 4'],
            ['test 6', 'test 5'],
          ],
        },
      },
    }).$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    location.hash = '';
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

  it('renders column names', () => {
    expect(
      vm.$el.querySelector('th:nth-child(2)').textContent.trim(),
    ).toBe('test');

    expect(
      vm.$el.querySelector('th:nth-child(3)').textContent.trim(),
    ).toBe('test 2');
  });

  describe('row rendering', () => {
    it('renders row numbers', () => {
      expect(
        vm.$el.querySelector('td:first-child').textContent.trim(),
      ).toBe('1');
    });

    it('updates hash when clicking line number', (done) => {
      vm.$el.querySelector('td:first-child a').click();

      Vue.nextTick(() => {
        expect(
          location.hash,
        ).toBe('#L1');

        done();
      });
    });

    it('calls updateCurrentLineNumber when clicking line number', (done) => {
      spyOn(vm, 'updateCurrentLineNumber');

      vm.$el.querySelector('td:first-child a').click();

      Vue.nextTick(() => {
        expect(
          vm.updateCurrentLineNumber,
        ).toHaveBeenCalledWith(0);

        done();
      });
    });
  });
});
