/* eslint-disable no-new */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import BlobViewer from '~/blob/viewer/index';
import axios from '~/lib/utils/axios_utils';

describe('Blob viewer', () => {
  let blob;
  let mock;

  preloadFixtures('snippets/show.html');

  const asyncClick = () =>
    new Promise(resolve => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(resolve);
    });

  beforeEach(() => {
    mock = new MockAdapter(axios);

    loadFixtures('snippets/show.html');
    $('#modal-upload-blob').remove();

    blob = new BlobViewer();

    mock.onGet('http://test.host/snippets/1.json?viewer=rich').reply(200, {
      html: '<div>testing</div>',
    });

    mock.onGet('http://test.host/snippets/1.json?viewer=simple').reply(200, {
      html: '<div>testing</div>',
    });

    spyOn(axios, 'get').and.callThrough();
  });

  afterEach(() => {
    mock.restore();
    window.location.hash = '';
  });

  it('loads source file after switching views', done => {
    document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

    setTimeout(() => {
      expect(
        document
          .querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('loads source file when line number is in hash', done => {
    window.location.hash = '#L1';

    new BlobViewer();

    setTimeout(() => {
      expect(
        document
          .querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('doesnt reload file if already loaded', done => {
    asyncClick()
      .then(() => asyncClick())
      .then(() => {
        expect(document.querySelector('.blob-viewer[data-type="simple"]').dataset.loaded).toBe(
          'true',
        );

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
      expect(copyButton.classList.contains('disabled')).toBeTruthy();
    });

    it('has tooltip when disabled', () => {
      expect(copyButton.dataset.title).toBe('Switch to the source to copy the file contents');
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

    it('enables after switching to simple view', done => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect(copyButton.classList.contains('disabled')).toBeFalsy();

        done();
      });
    });

    it('updates tooltip after switching to simple view', done => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setTimeout(() => {
        expect(copyButton.dataset.title).toBe('Copy file contents');

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

      expect(simpleBtn.classList.contains('active')).toBeTruthy();

      expect(simpleBtn.blur).toHaveBeenCalled();
    });

    it('sends AJAX request when switching to simple view', () => {
      blob.switchToViewer('simple');

      expect(axios.get).toHaveBeenCalled();
    });

    it('does not send AJAX request when switching to rich view', () => {
      blob.switchToViewer('simple');
      blob.switchToViewer('rich');

      expect(axios.get.calls.count()).toBe(1);
    });
  });

  describe('a URL inside the blob content', () => {
    beforeEach(() => {
      mock.onGet('http://test.host/snippets/1.json?viewer=simple').reply(200, {
        html:
          '<div class="js-blob-content"><pre class="code"><code><span class="line" lang="yaml"><span class="c1">To install gitlab-shell you also need a Go compiler version 1.8 or newer. https://golang.org/dl/</span></span></code></pre></div>',
      });
    });

    it('is rendered as a link in simple view', done => {
      asyncClick()
        .then(() => {
          expect(document.querySelector('.blob-viewer[data-type="simple"]').innerHTML).toContain(
            '<a href="https://golang.org/dl/">https://golang.org/dl/</a>',
          );
          done();
        })
        .catch(() => {
          fail();
          done();
        });
    });
  });
});
