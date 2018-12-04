import blobBundle from '~/blob_edit/blob_bundle';
import $ from 'jquery';

window.ace = {
  config: {
    set: () => {},
    loadModule: () => {},
  },
  edit: () => ({ focus: () => {} }),
};

describe('EditBlob', () => {
  beforeEach(() => {
    setFixtures(`
      <div class="js-edit-blob-form">
        <button class="js-commit-button"></button>
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
});
