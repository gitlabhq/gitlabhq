/* global Notes */

import 'vendor/autosize';
import '~/gl_form';
import '~/lib/utils/text_utility';
import '~/render_gfm';
import '~/render_math';
import '~/notes';

fdescribe('Merge request notes', () => {
  window.gon = window.gon || {};
  window.gl = window.gl || {};
  gl.utils = gl.utils || {};

  const fixture = 'merge_requests/diff_comment.html.raw';
  preloadFixtures(fixture);

  beforeEach(() => {
    loadFixtures(fixture);
    gl.utils.disableButtonIfEmptyField = _.noop;
    window.project_uploads_path = 'http://test.host/uploads';
    $('body').data('page', 'projects:merge_requests:show');
    window.gon.current_user_id = $('.note:last').data('author-id');

    return new Notes('', []);
  });

  describe('up arrow', () => {
    it('edits last comment when triggered in main form', () => {
      const upArrowEvent = $.Event('keydown');
      upArrowEvent.which = 38;

      spyOnEvent('.note:last .js-note-edit', 'click');

      $('.js-note-text').trigger(upArrowEvent);

      expect('click').toHaveBeenTriggeredOn('.note:last .js-note-edit');
    });

    it('edits last comment in discussion when triggered in discussion form', (done) => {
      const upArrowEvent = $.Event('keydown');
      upArrowEvent.which = 38;

      spyOnEvent('.note-discussion .js-note-edit', 'click');

      $('.js-discussion-reply-button').click();

      setTimeout(() => {
        expect(
          $('.note-discussion .js-note-text'),
        ).toExist();

        $('.note-discussion .js-note-text').trigger(upArrowEvent);

        expect('click').toHaveBeenTriggeredOn('.note-discussion .js-note-edit');

        done();
      });
    });
  });
});
