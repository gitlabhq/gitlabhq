/* eslint-disable space-before-function-paren, no-unused-expressions, no-var, object-shorthand, comma-dangle, max-len */
/* global Notes */

require('~/notes');
require('vendor/autosize');
require('~/gl_form');
require('~/lib/utils/text_utility');

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
          discussion_html: null,
          valid: true,
          html: '<div></div>',
        };
        $notesList = jasmine.createSpyObj('$notesList', ['find']);

        notes = jasmine.createSpyObj('notes', [
          'refresh',
          'isNewNote',
          'collapseLongCommitList',
          'updateNotesCount',
        ]);
        notes.taskList = jasmine.createSpyObj('tasklist', ['init']);
        notes.note_ids = [];

        spyOn(window, '$').and.returnValue($notesList);
        spyOn(gl.utils, 'localTimeAgo');
        spyOn(Notes, 'animateAppendNote');
        notes.isNewNote.and.returnValue(true);

        Notes.prototype.renderNote.call(notes, note);
      });

      it('should query for the notes list', () => {
        expect(window.$).toHaveBeenCalledWith('ul.main-notes-list');
      });

      it('should call .animateAppendNote', () => {
        expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.html, $notesList);
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
        let $notesList;
        let body;

        beforeEach(() => {
          body = jasmine.createSpyObj('body', ['attr']);
          discussionContainer = { length: 0 };

          spyOn(window, '$').and.returnValues(discussionContainer, body, $notesList);
          $form.closest.and.returnValues(row, $form);
          $form.find.and.returnValues(discussionContainer);
          body.attr.and.returnValue('');

          Notes.prototype.renderDiscussionNote.call(notes, note, $form);
        });

        it('should query for the notes list', () => {
          expect(window.$.calls.argsFor(2)).toEqual(['ul.main-notes-list']);
        });

        it('should call Notes.animateAppendNote', () => {
          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.discussion_html, $notesList);
        });
      });

      describe('Discussion sub note', () => {
        beforeEach(() => {
          discussionContainer = { length: 1 };

          spyOn(window, '$').and.returnValues(discussionContainer);
          $form.closest.and.returnValues(row);

          Notes.prototype.renderDiscussionNote.call(notes, note, $form);
        });

        it('should query foor the discussion container', () => {
          expect(window.$).toHaveBeenCalledWith(`.notes[data-discussion-id="${note.discussion_id}"]`);
        });

        it('should call Notes.animateAppendNote', () => {
          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.html, discussionContainer);
        });
      });
    });

    describe('animateAppendNote', () => {
      let noteHTML;
      let $note;
      let $notesList;

      beforeEach(() => {
        noteHTML = '<div></div>';
        $note = jasmine.createSpyObj('$note', ['addClass', 'renderGFM', 'removeClass']);
        $notesList = jasmine.createSpyObj('$notesList', ['append']);

        spyOn(window, '$').and.returnValue($note);
        spyOn(window, 'setTimeout').and.callThrough();
        $note.addClass.and.returnValue($note);
        $note.renderGFM.and.returnValue($note);

        Notes.animateAppendNote(noteHTML, $notesList);
      });

      it('should init the note jquery object', () => {
        expect(window.$).toHaveBeenCalledWith(noteHTML);
      });

      it('should call addClass', () => {
        expect($note.addClass).toHaveBeenCalledWith('fade-in');
      });
      it('should call renderGFM', () => {
        expect($note.renderGFM).toHaveBeenCalledWith();
      });

      it('should append note to the notes list', () => {
        expect($notesList.append).toHaveBeenCalledWith($note);
      });
    });
  });
}).call(window);
