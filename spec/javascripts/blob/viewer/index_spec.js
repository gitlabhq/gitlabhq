/* eslint-disable no-new */
import BlobViewer from '~/blob/viewer/index';

describe('Blob viewer', () => {
  let blob;
  preloadFixtures('blob/show.html.raw');

  beforeEach(() => {
    loadFixtures('blob/show.html.raw');
    $('#modal-upload-blob').remove();

    blob = new BlobViewer();

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
    let copyButton;

    beforeEach(() => {
      copyButton = document.querySelector('.js-copy-blob-source-btn');
    });

    it('disabled on load', () => {
      expect(
        copyButton.classList.contains('disabled'),
      ).toBeTruthy();
    });

    it('has tooltip when disabled', () => {
      expect(
        copyButton.getAttribute('data-original-title'),
      ).toBe('Switch to the source to copy it to the clipboard');
    });

    it('is blurred when clicked and disabled', () => {
      spyOn(copyButton, 'blur');

      copyButton.click();

      expect(copyButton.blur).toHaveBeenCalled();
    });

    it('is not blurred when clicked and not disabled', () => {
      spyOn(copyButton, 'blur');

      copyButton.classList.remove('disabled');
      copyButton.click();

      expect(copyButton.blur).not.toHaveBeenCalled();
    });

    it('enables after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect($.ajax).toHaveBeenCalled();
        expect(
          copyButton.classList.contains('disabled'),
        ).toBeFalsy();

        done();
      });
    });

    it('updates tooltip after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect($.ajax).toHaveBeenCalled();

        expect(
          copyButton.getAttribute('data-original-title'),
        ).toBe('Copy source to clipboard');

        done();
      });
    });
  });

  describe('switchToViewer', () => {
    it('removes active class from old viewer button', () => {
      blob.switchToViewer('simple');

      expect(
        document.querySelector('.js-blob-viewer-switch-btn.active[data-viewer="rich"]'),
      ).toBeNull();
    });

    it('adds active class to new viewer button', () => {
      const simpleBtn = document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]');

      spyOn(simpleBtn, 'blur');

      blob.switchToViewer('simple');

      expect(
        simpleBtn.classList.contains('active'),
      ).toBeTruthy();
      expect(simpleBtn.blur).toHaveBeenCalled();
    });

    it('sends AJAX request when switching to simple view', () => {
      blob.switchToViewer('simple');

      expect($.ajax).toHaveBeenCalled();
    });

    it('does not send AJAX request when switching to rich view', () => {
      blob.switchToViewer('simple');
      blob.switchToViewer('rich');

      expect($.ajax.calls.count()).toBe(1);
    });
  });
});
