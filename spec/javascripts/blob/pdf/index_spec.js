/* eslint-disable import/no-unresolved */

import renderPDF from '~/blob/pdf';
import testPDF from '../../fixtures/blob/pdf/test.pdf';

describe('PDF renderer', () => {
  let viewer;
  let app;

  const checkLoaded = (done) => {
    if (app.loading) {
      setTimeout(() => {
        checkLoaded(done);
      }, 100);
    } else {
      done();
    }
  };

  preloadFixtures('static/pdf_viewer.html.raw');

  beforeEach(() => {
    loadFixtures('static/pdf_viewer.html.raw');
    viewer = document.getElementById('js-pdf-viewer');
    viewer.dataset.endpoint = testPDF;
  });

  it('shows loading icon', () => {
    renderPDF();

    expect(
      document.querySelector('.loading'),
    ).not.toBeNull();
  });

  describe('successful response', () => {
    beforeEach((done) => {
      app = renderPDF();

      checkLoaded(done);
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('renders the PDF', () => {
      expect(
        document.querySelector('.pdf-viewer'),
      ).not.toBeNull();
    });

    it('renders the PDF page', () => {
      expect(
        document.querySelector('.pdf-page'),
      ).not.toBeNull();
    });
  });

  describe('error getting file', () => {
    beforeEach((done) => {
      viewer.dataset.endpoint = 'invalid/path/to/file.pdf';
      app = renderPDF();

      checkLoaded(done);
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('shows error message', () => {
      expect(
        document.querySelector('.md').textContent.trim(),
      ).toBe('An error occurred whilst loading the file. Please try again later.');
    });
  });
});
