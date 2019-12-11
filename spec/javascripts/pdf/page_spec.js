import Vue from 'vue';
import pdfjsLib from 'pdfjs-dist/build/pdf';
import workerSrc from 'pdfjs-dist/build/pdf.worker.min';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { FIXTURES_PATH } from 'spec/test_constants';
import PageComponent from '~/pdf/page/index.vue';

const testPDF = `${FIXTURES_PATH}/blob/pdf/test.pdf`;

describe('Page component', () => {
  const Component = Vue.extend(PageComponent);
  let vm;
  let testPage;

  beforeEach(done => {
    pdfjsLib.GlobalWorkerOptions.workerSrc = workerSrc;
    pdfjsLib
      .getDocument(testPDF)
      .promise.then(pdf => pdf.getPage(1))
      .then(page => {
        testPage = page;
      })
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the page when mounting', done => {
    const promise = Promise.resolve();
    spyOn(testPage, 'render').and.returnValue({ promise });

    vm = mountComponent(Component, {
      page: testPage,
      number: 1,
    });

    expect(vm.rendering).toBe(true);

    promise
      .then(() => {
        expect(testPage.render).toHaveBeenCalledWith(vm.renderContext);
        expect(vm.rendering).toBe(false);
      })
      .then(done)
      .catch(done.fail);
  });
});
