import renderPDF from '~/blob/pdf';
import testPDF from './test.pdf';

describe('PDF renderer', () => {
  let viewer;

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
      renderPDF();

      setTimeout(() => {
        done();
      }, 500);
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
      renderPDF();

      setTimeout(() => {
        done();
      }, 500);
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('shows error message', () => {
      expect(
        document.querySelector('.md').textContent.trim(),
      ).toBe('An error occured whilst loading the file. Please try again later.');
    });
  });
});
