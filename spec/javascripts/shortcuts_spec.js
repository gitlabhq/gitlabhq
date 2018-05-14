import $ from 'jquery';
import Shortcuts from '~/shortcuts';

describe('Shortcuts', () => {
  const fixtureName = 'merge_requests/diff_comment.html.raw';
  const createEvent = (type, target) => $.Event(type, {
    target,
  });

  preloadFixtures(fixtureName);

  describe('toggleMarkdownPreview', () => {
    beforeEach(() => {
      loadFixtures(fixtureName);

      spyOnEvent('.js-new-note-form .js-md-preview-button', 'focus');
      spyOnEvent('.edit-note .js-md-preview-button', 'focus');

      new Shortcuts(); // eslint-disable-line no-new
    });

    it('focuses preview button in form', () => {
      Shortcuts.toggleMarkdownPreview(
        createEvent('KeyboardEvent', document.querySelector('.js-new-note-form .js-note-text'),
      ));

      expect('focus').toHaveBeenTriggeredOn('.js-new-note-form .js-md-preview-button');
    });

    it('focues preview button inside edit comment form', (done) => {
      document.querySelector('.js-note-edit').click();

      setTimeout(() => {
        Shortcuts.toggleMarkdownPreview(
          createEvent('KeyboardEvent', document.querySelector('.edit-note .js-note-text'),
        ));

        expect('focus').not.toHaveBeenTriggeredOn('.js-new-note-form .js-md-preview-button');
        expect('focus').toHaveBeenTriggeredOn('.edit-note .js-md-preview-button');

        done();
      });
    });
  });
});
