import $ from 'jquery';
import BlobFileDropzone from '~/blob/blob_file_dropzone';

describe('BlobFileDropzone', function() {
  preloadFixtures('blob/show.html');

  beforeEach(() => {
    loadFixtures('blob/show.html');
    const form = $('.js-upload-blob-form');
    this.blobFileDropzone = new BlobFileDropzone(form, 'POST');
    this.dropzone = $('.js-upload-blob-form .dropzone').get(0).dropzone;
    this.replaceFileButton = $('#submit-all');
  });

  describe('submit button', () => {
    it('requires file', () => {
      spyOn(window, 'alert');

      this.replaceFileButton.click();

      expect(window.alert).toHaveBeenCalled();
    });

    it('is disabled while uploading', () => {
      spyOn(window, 'alert');

      const file = new File([], 'some-file.jpg');
      const fakeEvent = $.Event('drop', {
        dataTransfer: { files: [file] },
      });

      this.dropzone.listeners[0].events.drop(fakeEvent);
      this.replaceFileButton.click();

      expect(window.alert).not.toHaveBeenCalled();
      expect(this.replaceFileButton.is(':disabled')).toEqual(true);
    });
  });
});
