import Vue from 'vue';
import pdfjsLib from 'vendor/pdf';
import workerSrc from 'vendor/pdf.worker.min';

import PageComponent from '~/pdf/page/index.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import testPDF from 'spec/fixtures/blob/pdf/test.pdf';

describe('Page component', () => {
  const Component = Vue.extend(PageComponent);
  let vm;
  let testPage;

  beforeEach(done => {
    pdfjsLib.PDFJS.workerSrc = workerSrc;
    pdfjsLib
      .getDocument(testPDF)
      .then(pdf => pdf.getPage(1))
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
    spyOn(testPage, 'render').and.callFake(() => promise);
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
