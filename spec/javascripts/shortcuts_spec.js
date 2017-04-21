/* global Shortcuts */
describe('Shortcuts', () => {
  const fixtureName = 'issues/open-issue.html.raw';

  preloadFixtures(fixtureName);

  describe('toggleMarkdownPreview', () => {
    let sc;
    let event;

    beforeEach(() => {
      loadFixtures(fixtureName);

      spyOnEvent('.js-md-preview-button', 'focus');

      event = $.Event('', {
        target: document.querySelector('.js-note-text'),
      });

      sc = new Shortcuts();
    });

    it('focuses preview button in form', () => {
      sc.toggleMarkdownPreview(event);

      expect('focus').toHaveBeenTriggeredOn('.js-md-preview-button');
    });
  });
});
