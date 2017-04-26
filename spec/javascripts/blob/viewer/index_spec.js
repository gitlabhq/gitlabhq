/* eslint-disable no-new */
import BlobViewer from '~/blob/viewer/index';

fdescribe('Blob viewer', () => {
  preloadFixtures('blob/show.html.raw');

  beforeEach(() => {
    loadFixtures('blob/show.html.raw');
    $('#modal-upload-blob').remove();

    new BlobViewer();

    spyOn($, 'ajax').and.callFake(() => {
      const d = $.Deferred();

      d.resolve({
        html: '<div>testing</div>',
      });

      return d.promise();
    });
  });

  afterEach(() => {
    location.hash = '';
  });

  it('loads source file after switching views', (done) => {
    document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

    setTimeout(() => {
      expect($.ajax).toHaveBeenCalled();
      expect(
        document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('loads source file when line number is in hash', (done) => {
    location.hash = '#L1';

    new BlobViewer();

    setTimeout(() => {
      expect($.ajax).toHaveBeenCalled();
      expect(
        document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('doesnt reload file if already loaded', (done) => {
    const asyncClick = () => new Promise((resolve) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(resolve);
    });

    asyncClick()
      .then(() => {
        expect($.ajax).toHaveBeenCalled();
        return asyncClick();
      })
      .then(() => {
        expect($.ajax.calls.count()).toBe(1);
        expect(
          document.querySelector('.blob-viewer[data-type="simple"]').getAttribute('data-loaded'),
        ).toBe('true');

        done();
      })
      .catch(() => {
        fail();
        done();
      });
  });

  describe('copy blob button', () => {
    it('disabled on load', () => {
      expect(
        document.querySelector('.js-copy-blob-source-btn').classList.contains('disabled'),
      ).toBeTruthy();
    });

    it('has tooltip when disabled', () => {
      expect(
        document.querySelector('.js-copy-blob-source-btn').getAttribute('data-original-title'),
      ).toBe('Switch to the source to copy it to the clipboard');
    });

    it('enables after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect($.ajax).toHaveBeenCalled();
        expect(
          document.querySelector('.js-copy-blob-source-btn').classList.contains('disabled'),
        ).toBeFalsy();

        done();
      });
    });

    it('updates tooltip after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect($.ajax).toHaveBeenCalled();

        expect(
          document.querySelector('.js-copy-blob-source-btn').getAttribute('data-original-title'),
        ).toBe('Copy source to clipboard');

        done();
      });
    });
  });
});
