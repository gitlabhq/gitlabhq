/* eslint-disable import/no-unresolved */

import Vue from 'vue';
import { PDFJS } from 'vendor/pdf';
import workerSrc from 'vendor/pdf.worker.min';

import PDFLab from '~/pdf/index.vue';
import pdf from '../fixtures/blob/pdf/test.pdf';

PDFJS.workerSrc = workerSrc;
const Component = Vue.extend(PDFLab);

describe('PDF component', () => {
  let vm;

  const checkLoaded = (done) => {
    if (vm.loading) {
      setTimeout(() => {
        checkLoaded(done);
      }, 100);
    } else {
      done();
    }
  };

  describe('without PDF data', () => {
    beforeEach((done) => {
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
    beforeEach((done) => {
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
