import Vue from 'vue';
import { GlobalWorkerOptions } from 'pdfjs-dist/build/pdf';
import workerSrc from 'pdfjs-dist/build/pdf.worker.min';

import { FIXTURES_PATH } from 'spec/test_constants';
import PDFLab from '~/pdf/index.vue';

const pdf = `${FIXTURES_PATH}/blob/pdf/test.pdf`;

GlobalWorkerOptions.workerSrc = workerSrc;
const Component = Vue.extend(PDFLab);

describe('PDF component', () => {
  let vm;

  const checkLoaded = done => {
    if (vm.loading) {
      setTimeout(() => {
        checkLoaded(done);
      }, 100);
    } else {
      done();
    }
  };

  describe('without PDF data', () => {
    beforeEach(done => {
      vm = new Component({
        propsData: {
          pdf: '',
        },
      });

      vm.$mount();

      checkLoaded(done);
    });

    it('does not render', () => {
      expect(vm.$el.tagName).toBeUndefined();
    });
  });

  describe('with PDF data', () => {
    beforeEach(done => {
      vm = new Component({
        propsData: {
          pdf,
        },
      });

      vm.$mount();

      checkLoaded(done);
    });

    it('renders pdf component', () => {
      expect(vm.$el.tagName).toBeDefined();
    });
  });
});
