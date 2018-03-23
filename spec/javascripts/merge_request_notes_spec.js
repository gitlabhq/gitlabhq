import $ from 'jquery';
import _ from 'underscore';
import 'autosize';
import '~/gl_form';
import '~/lib/utils/text_utility';
import '~/render_gfm';
import '~/render_math';
import Notes from '~/notes';

const upArrowKeyCode = 38;

describe('Merge request notes', () => {
  window.gon = window.gon || {};
  window.gl = window.gl || {};
  gl.utils = gl.utils || {};

  const discussionTabFixture = 'merge_requests/diff_comment.html.raw';
  const changesTabJsonFixture = 'merge_request_diffs/inline_changes_tab_with_comments.json';
  preloadFixtures(discussionTabFixture, changesTabJsonFixture);

  describe('Discussion tab with diff comments', () => {
    beforeEach(() => {
      loadFixtures(discussionTabFixture);
      gl.utils.disableButtonIfEmptyField = _.noop;
      window.project_uploads_path = 'http://test.host/uploads';
      $('body').attr('data-page', 'projects:merge_requests:show');
      window.gon.current_user_id = $('.note:last').data('authorId');

      return new Notes('', []);
    });

    afterEach(() => {
      // Undo what we did to the shared <body>
      $('body').removeAttr('data-page');
    });

    describe('up arrow', () => {
      it('edits last comment when triggered in main form', () => {
        const upArrowEvent = $.Event('keydown');
        upArrowEvent.which = upArrowKeyCode;

        spyOnEvent('.note:last .js-note-edit', 'click');

        $('.js-note-text').trigger(upArrowEvent);

        expect('click').toHaveBeenTriggeredOn('.note:last .js-note-edit');
      });

      it('edits last comment in discussion when triggered in discussion form', (done) => {
        const upArrowEvent = $.Event('keydown');
        upArrowEvent.which = upArrowKeyCode;

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

  describe('Changes tab with diff comments', () => {
    beforeEach(() => {
      const diffsResponse = getJSONFixture(changesTabJsonFixture);
      const noteFormHtml = `<form class="js-new-note-form">
        <textarea class="js-note-text"></textarea>
      </form>`;
      setFixtures(diffsResponse.html + noteFormHtml);
      $('body').attr('data-page', 'projects:merge_requests:show');
      window.gon.current_user_id = $('.note:last').data('authorId');

      return new Notes('', []);
    });

    afterEach(() => {
      // Undo what we did to the shared <body>
      $('body').removeAttr('data-page');
    });

    describe('up arrow', () => {
      it('edits last comment in discussion when triggered in discussion form', (done) => {
        const upArrowEvent = $.Event('keydown');
        upArrowEvent.which = upArrowKeyCode;

        spyOnEvent('.note:last .js-note-edit', 'click');

        $('.js-discussion-reply-button').trigger('click');

        setTimeout(() => {
          $('.js-note-text').trigger(upArrowEvent);

          expect('click').toHaveBeenTriggeredOn('.note:last .js-note-edit');

          done();
        });
      });
    });
  });
});
