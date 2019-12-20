import $ from 'jquery';
import blobBundle from '~/blob_edit/blob_bundle';

describe('BlobBundle', () => {
  beforeEach(() => {
    spyOnDependency(blobBundle, 'EditBlob').and.stub();
    setFixtures(`
      <div class="js-edit-blob-form" data-blob-filename="blah">
        <button class="js-commit-button"></button>
        <a class="btn btn-cancel" href="#"></a>
      </div>`);
    blobBundle();
  });

  it('sets the window beforeunload listener to a function returning a string', () => {
    expect(window.onbeforeunload()).toBe('');
  });

  it('removes beforeunload listener if commit button is clicked', () => {
    $('.js-commit-button').click();

    expect(window.onbeforeunload).toBeNull();
  });

  it('removes beforeunload listener when cancel link is clicked', () => {
    $('.btn.btn-cancel').click();

    expect(window.onbeforeunload).toBeNull();
  });
});
