/* eslint-disable import/no-unresolved */

import Vue from 'vue';
import pdfjsLib from 'vendor/pdf';
import workerSrc from 'vendor/pdf.worker.min';

import PageComponent from '~/pdf/page/index.vue';
import testPDF from '../fixtures/blob/pdf/test.pdf';

const Component = Vue.extend(PageComponent);

describe('Page component', () => {
  let vm;
  let testPage;
  pdfjsLib.PDFJS.workerSrc = workerSrc;

  const checkRendered = (done) => {
    if (vm.rendering) {
      setTimeout(() => {
        checkRendered(done);
      }, 100);
    } else {
      done();
    }
  };

  beforeEach((done) => {
    pdfjsLib.getDocument(testPDF)
      .then(pdf => pdf.getPage(1))
      .then((page) => {
        testPage = page;
        done();
      })
      .catch((error) => {
        console.error(error);
      });
  });

  describe('render', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          page: testPage,
          number: 1,
        },
      });

      vm.$mount();

      checkRendered(done);
    });

    it('renders first page', () => {
      expect(vm.$el.tagName).toBeDefined();
    });
  });
});
