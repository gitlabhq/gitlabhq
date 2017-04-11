import Vue from 'vue';
import Service from '~/blob/xlsx/service';
import component from '~/blob/xlsx/index.vue';

describe('XLSX Renderer', () => {
  let vm;

  beforeEach((done) => {
    const RendererComponent = Vue.extend(component);

    spyOn(Service.prototype, 'getData').and.callFake(() => new Promise((resolve) => {
      resolve({
        test: {},
        'test 1': {},
      });

      setTimeout(done, 0);
    }));

    vm = new RendererComponent({
      propsData: {
        endpoint: '/',
      },
    }).$mount();
  });

  afterEach(() => {
    location.hash = '';
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
});
