/* eslint-disable space-before-function-paren, no-unused-expressions, no-var, object-shorthand, comma-dangle, max-len */
/* global Notes */

import 'vendor/autosize';
import '~/gl_form';
import '~/lib/utils/text_utility';
import '~/render_gfm';
import '~/render_math';
import '~/notes';

(function() {
  window.gon || (window.gon = {});
  window.gl = window.gl || {};
  gl.utils = gl.utils || {};

  describe('Notes', function() {
    var commentsTemplate = 'issues/issue_with_comment.html.raw';
    preloadFixtures(commentsTemplate);

    beforeEach(function () {
      loadFixtures(commentsTemplate);
      gl.utils.disableButtonIfEmptyField = _.noop;
      window.project_uploads_path = 'http://test.host/uploads';
      $('body').data('page', 'projects:issues:show');
    });

    describe('task lists', function() {
      beforeEach(function() {
        $('form').on('submit', function(e) {
          e.preventDefault();
        });
        this.notes = new Notes();
      });

      it('modifies the Markdown field', function() {
        $('input[type=checkbox]').attr('checked', true).trigger('change');
        expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });

      it('submits an ajax request on tasklist:changed', function() {
        spyOn(jQuery, 'ajax').and.callFake(function(req) {
          expect(req.type).toBe('PATCH');
          expect(req.url).toBe('http://test.host/frontend-fixtures/issues-project/notes/1');
          return expect(req.data.note).not.toBe(null);
        });
        $('.js-task-list-field').trigger('tasklist:changed');
      });
    });

    describe('comments', function() {
      var textarea = '.js-note-text';

      beforeEach(function() {
        this.notes = new Notes();

        this.autoSizeSpy = spyOnEvent($(textarea), 'autosize:update');
        spyOn(this.notes, 'renderNote').and.stub();

        $(textarea).data('autosave', {
          reset: function() {}
        });

        $('form').on('submit', function(e) {
          e.preventDefault();
          $('.js-main-target-form').trigger('ajax:success');
        });
      });

      it('autosizes after comment submission', function() {
        $(textarea).text('This is an example comment note');
        expect(this.autoSizeSpy).not.toHaveBeenTriggered();

        $('.js-comment-button').click();
        expect(this.autoSizeSpy).toHaveBeenTriggered();
      });
    });

    describe('renderNote', () => {
      let notes;
      let note;
      let $notesList;

      beforeEach(() => {
        note = {
          id: 1,
          discussion_html: null,
          valid: true,
          note: 'heya',
          html: '<div>heya</div>',
        };
        $notesList = jasmine.createSpyObj('$notesList', [
          'find',
          'append',
        ]);

        notes = jasmine.createSpyObj('notes', [
          'refresh',
          'isNewNote',
          'isUpdatedNote',
          'collapseLongCommitList',
          'updateNotesCount',
          'putConflictEditWarningInPlace'
        ]);
        notes.taskList = jasmine.createSpyObj('tasklist', ['init']);
        notes.note_ids = [];
        notes.updatedNotesTrackingMap = {};

        spyOn(gl.utils, 'localTimeAgo');
        spyOn(Notes, 'animateAppendNote').and.callThrough();
        spyOn(Notes, 'animateUpdateNote').and.callThrough();
      });

      describe('when adding note', () => {
        it('should call .animateAppendNote', () => {
          notes.isNewNote.and.returnValue(true);
          Notes.prototype.renderNote.call(notes, note, null, $notesList);

          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.html, $notesList);
        });
      });

      describe('when note was edited', () => {
        it('should call .animateUpdateNote', () => {
          notes.isUpdatedNote.and.returnValue(true);
          const $note = $('<div>');
          $notesList.find.and.returnValue($note);
          Notes.prototype.renderNote.call(notes, note, null, $notesList);

          expect(Notes.animateUpdateNote).toHaveBeenCalledWith(note.html, $note);
        });

        describe('while editing', () => {
          it('should update textarea if nothing has been touched', () => {
            notes.isUpdatedNote.and.returnValue(true);
            const $note = $(`<div class="is-editing">
              <div class="original-note-content">initial</div>
              <textarea class="js-note-text">initial</textarea>
            </div>`);
            $notesList.find.and.returnValue($note);
            Notes.prototype.renderNote.call(notes, note, null, $notesList);

            expect($note.find('.js-note-text').val()).toEqual(note.note);
          });

          it('should call .putConflictEditWarningInPlace', () => {
            notes.isUpdatedNote.and.returnValue(true);
            const $note = $(`<div class="is-editing">
              <div class="original-note-content">initial</div>
              <textarea class="js-note-text">different</textarea>
            </div>`);
            $notesList.find.and.returnValue($note);
            Notes.prototype.renderNote.call(notes, note, null, $notesList);

            expect(notes.putConflictEditWarningInPlace).toHaveBeenCalledWith(note, $note);
          });
        });
      });
    });

    describe('renderDiscussionNote', () => {
      let discussionContainer;
      let note;
      let notes;
      let $form;
      let row;

      beforeEach(() => {
        note = {
          html: '<li></li>',
          discussion_html: '<div></div>',
          discussion_id: 1,
          discussion_resolvable: false,
          diff_discussion_html: false,
        };
        $form = jasmine.createSpyObj('$form', ['closest', 'find']);
        row = jasmine.createSpyObj('row', ['prevAll', 'first', 'find']);

        notes = jasmine.createSpyObj('notes', [
          'isNewNote',
          'isParallelView',
          'updateNotesCount',
        ]);
        notes.note_ids = [];

        spyOn(gl.utils, 'localTimeAgo');
        spyOn(Notes, 'animateAppendNote');
        notes.isNewNote.and.returnValue(true);
        notes.isParallelView.and.returnValue(false);
        row.prevAll.and.returnValue(row);
        row.first.and.returnValue(row);
        row.find.and.returnValue(row);
      });

      describe('Discussion root note', () => {
        let body;

        beforeEach(() => {
          body = jasmine.createSpyObj('body', ['attr']);
          discussionContainer = { length: 0 };

          $form.closest.and.returnValues(row, $form);
          $form.find.and.returnValues(discussionContainer);
          body.attr.and.returnValue('');

          Notes.prototype.renderDiscussionNote.call(notes, note, $form);
        });

        it('should call Notes.animateAppendNote', () => {
          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.discussion_html, $('.main-notes-list'));
        });
      });

      describe('Discussion sub note', () => {
        beforeEach(() => {
          discussionContainer = { length: 1 };

          $form.closest.and.returnValues(row, $form);
          $form.find.and.returnValues(discussionContainer);

          Notes.prototype.renderDiscussionNote.call(notes, note, $form);
        });

        it('should call Notes.animateAppendNote', () => {
          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.html, discussionContainer);
        });
      });
    });

    describe('animateAppendNote', () => {
      let noteHTML;
      let $notesList;
      let $resultantNote;

      beforeEach(() => {
        noteHTML = '<div></div>';
        $notesList = jasmine.createSpyObj('$notesList', ['append']);

        $resultantNote = Notes.animateAppendNote(noteHTML, $notesList);
      });

      it('should have `fade-in` class', () => {
        expect($resultantNote.hasClass('fade-in')).toEqual(true);
      });

      it('should append note to the notes list', () => {
        expect($notesList.append).toHaveBeenCalledWith($resultantNote);
      });
    });

    describe('animateUpdateNote', () => {
      let noteHTML;
      let $note;
      let $updatedNote;

      beforeEach(() => {
        noteHTML = '<div></div>';
        $note = jasmine.createSpyObj('$note', [
          'replaceWith'
        ]);

        $updatedNote = Notes.animateUpdateNote(noteHTML, $note);
      });

      it('should have `fade-in` class', () => {
        expect($updatedNote.hasClass('fade-in')).toEqual(true);
      });

      it('should call replaceWith on $note', () => {
        expect($note.replaceWith).toHaveBeenCalledWith($updatedNote);
      });
    });
  });
}).call(window);
