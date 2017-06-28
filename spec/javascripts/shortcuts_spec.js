/* global Shortcuts */
describe('Shortcuts', () => {
  const fixtureName = 'issues/issue_with_comment.html.raw';
  const createEvent = (type, target) => $.Event(type, {
    target,
  });

  preloadFixtures(fixtureName);

  describe('toggleMarkdownPreview', () => {
    let sc;

    beforeEach(() => {
      loadFixtures(fixtureName);

      spyOnEvent('.js-new-note-form .js-md-preview-button', 'focus');
      spyOnEvent('.edit-note .js-md-preview-button', 'focus');

      sc = new Shortcuts();
    });

    it('focuses preview button in form', () => {
      sc.toggleMarkdownPreview(
        createEvent('KeyboardEvent', document.querySelector('.js-new-note-form .js-note-text'),
      ));

      expect('focus').toHaveBeenTriggeredOn('.js-new-note-form .js-md-preview-button');
    });

    it('focues preview button inside edit comment form', (done) => {
      document.querySelector('.js-note-edit').click();

      setTimeout(() => {
        sc.toggleMarkdownPreview(
          createEvent('KeyboardEvent', document.querySelector('.edit-note .js-note-text'),
        ));

        expect('focus').not.toHaveBeenTriggeredOn('.js-new-note-form .js-md-preview-button');
        expect('focus').toHaveBeenTriggeredOn('.edit-note .js-md-preview-button');

        done();
      });
    });
  });
});
