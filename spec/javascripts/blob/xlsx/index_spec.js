import Vue from 'vue';
import Service from '~/blob/xlsx/service';
import component from '~/blob/xlsx/index.vue';
import eventHub from '~/blob/xlsx/eventhub';

describe('XLSX Renderer', () => {
  let vm;

  beforeEach((done) => {
    const RendererComponent = Vue.extend(component);

    spyOn(Service.prototype, 'getData').and.callFake(() => new Promise((resolve) => {
      resolve({
        test: {
          columns: 1,
        },
        'test 1': {
          columns: 2,
        },
      });

      setTimeout(done, 0);
    }));

    spyOn(eventHub, '$off');

    vm = new RendererComponent({
      propsData: {
        endpoint: '/',
      },
    }).$mount();
  });

  afterEach(() => {
    location.hash = '';
  });

  it('sheetNames returns array of sheet names', () => {
    expect(
      vm.sheetNames,
    ).toEqual(['test', 'test 1']);
  });

  it('sheet returns currently selected sheet', () => {
    expect(
      vm.sheet,
    ).toEqual({
      columns: 1,
    });
  });

  describe('getInitialSheet', () => {
    it('defaults to first sheet', () => {
      expect(
        vm.currentSheetName,
      ).toBe('test');
    });

    it('uses hash for currentSheetName', () => {
      location.hash = 'test 1';

      expect(
        vm.getInitialSheet(),
      ).toBe('test 1');
    });

    it('defaults to first sheet if hash is not found in sheetNames', () => {
      location.hash = 'test 2';

      expect(
        vm.getInitialSheet(),
      ).toBe('test');
    });
  });

  it('removes eventHub listener on destroy', () => {
    vm.$destroy();

    expect(
      eventHub.$off,
    ).toHaveBeenCalledWith('update-sheet', vm.updateSheetName);
  });
});
