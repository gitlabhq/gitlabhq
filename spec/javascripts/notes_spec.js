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
        $('.js-comment-button').on('click', function(e) {
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

        $('.js-comment-button').on('click', (e) => {
          const $form = $(this);
          e.preventDefault();
          this.notes.addNote($form);
          this.notes.reenableTargetFormSubmitButton(e);
          this.notes.resetMainTargetForm(e);
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

      it('should have `fade-in-full` class', () => {
        expect($resultantNote.hasClass('fade-in-full')).toEqual(true);
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

    describe('getFormData', () => {
      it('should return form metadata object from form reference', () => {
        this.notes = new Notes();

        const $form = $('form');
        const sampleComment = 'foobar';
        $form.find('textarea.js-note-text').val(sampleComment);
        const { formData, formContent, formAction } = this.notes.getFormData($form);

        expect(formData.indexOf(sampleComment) > -1).toBe(true);
        expect(formContent).toEqual(sampleComment);
        expect(formAction).toEqual($form.attr('action'));
      });
    });

    describe('hasSlashCommands', () => {
      beforeEach(() => {
        this.notes = new Notes();
      });

      it('should return true when comment has slash commands', () => {
        const sampleComment = '/wip /milestone %1.0 /merge /unassign Merging this';
        const hasSlashCommands = this.notes.hasSlashCommands(sampleComment);

        expect(hasSlashCommands).toBeTruthy();
      });

      it('should return false when comment does NOT have any slash commands', () => {
        const sampleComment = 'Looking good, Awesome!';
        const hasSlashCommands = this.notes.hasSlashCommands(sampleComment);

        expect(hasSlashCommands).toBeFalsy();
      });
    });

    describe('stripSlashCommands', () => {
      const REGEX_SLASH_COMMANDS = /\/\w+/g;

      it('should strip slash commands from the comment', () => {
        this.notes = new Notes();
        const sampleComment = '/wip /milestone %1.0 /merge /unassign Merging this';
        const stripedComment = this.notes.stripSlashCommands(sampleComment);

        expect(REGEX_SLASH_COMMANDS.test(stripedComment)).toBeFalsy();
      });
    });

    describe('createPlaceholderNote', () => {
      const sampleComment = 'foobar';
      const uniqueId = 'b1234-a4567';
      const currentUsername = 'root';
      const currentUserFullname = 'Administrator';

      beforeEach(() => {
        this.notes = new Notes();
      });

      it('should return constructed placeholder element for regular note based on form contents', () => {
        const $tempNote = this.notes.createPlaceholderNote({
          formContent: sampleComment,
          uniqueId,
          isDiscussionNote: false,
          currentUsername,
          currentUserFullname
        });
        const $tempNoteHeader = $tempNote.find('.note-header');

        expect($tempNote.prop('nodeName')).toEqual('LI');
        expect($tempNote.attr('id')).toEqual(uniqueId);
        $tempNote.find('.timeline-icon > a, .note-header-info > a').each(function() {
          expect($(this).attr('href')).toEqual(`/${currentUsername}`);
        });
        expect($tempNote.find('.timeline-content').hasClass('discussion')).toBeFalsy();
        expect($tempNoteHeader.find('.hidden-xs').text().trim()).toEqual(currentUserFullname);
        expect($tempNoteHeader.find('.note-headline-light').text().trim()).toEqual(`@${currentUsername}`);
        expect($tempNote.find('.note-body .note-text').text().trim()).toEqual(sampleComment);
      });

      it('should return constructed placeholder element for discussion note based on form contents', () => {
        const $tempNote = this.notes.createPlaceholderNote({
          formContent: sampleComment,
          uniqueId,
          isDiscussionNote: true,
          currentUsername,
          currentUserFullname
        });

        expect($tempNote.prop('nodeName')).toEqual('LI');
        expect($tempNote.find('.timeline-content').hasClass('discussion')).toBeTruthy();
      });
    });

    describe('postComment & updateComment', () => {
      const sampleComment = 'foo';
      const updatedComment = 'bar';
      const note = {
        id: 1234,
        html: `<li class="note note-row-1234 timeline-entry" id="note_1234">
                <div class="note-text">${sampleComment}</div>
               </li>`,
        note: sampleComment,
        valid: true
      };
      let $form;
      let $notesContainer;

      beforeEach(() => {
        this.notes = new Notes();
        window.gon.current_username = 'root';
        window.gon.current_user_fullname = 'Administrator';
        $form = $('form');
        $notesContainer = $('ul.main-notes-list');
        $form.find('textarea.js-note-text').val(sampleComment);
        $('.js-comment-button').click();
      });

      it('should show placeholder note while new comment is being posted', () => {
        expect($notesContainer.find('.note.being-posted').length > 0).toEqual(true);
      });

      it('should remove placeholder note when new comment is done posting', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          expect($notesContainer.find('.note.being-posted').length).toEqual(0);
        });
      });

      it('should show actual note element when new comment is done posting', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          expect($notesContainer.find(`#${note.id}`).length > 0).toEqual(true);
        });
      });

      it('should reset Form when new comment is done posting', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          expect($form.find('textarea.js-note-text')).toEqual('');
        });
      });

      it('should trigger ajax:success event on Form when new comment is done posting', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          spyOn($form, 'trigger');
          expect($form.trigger).toHaveBeenCalledWith('ajax:success', [note]);
        });
      });

      it('should show flash error message when new comment failed to be posted', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.error();
          expect($notesContainer.parent().find('.flash-container .flash-text').is(':visible')).toEqual(true);
        });
      });

      it('should refill form textarea with original comment content when new comment failed to be posted', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.error();
          expect($form.find('textarea.js-note-text')).toEqual(sampleComment);
        });
      });

      it('should show updated comment as _actively being posted_ while comment being updated', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          const $noteEl = $notesContainer.find(`#note_${note.id}`);
          $noteEl.find('.js-note-edit').click();
          $noteEl.find('textarea.js-note-text').val(updatedComment);
          $noteEl.find('.js-comment-save-button').click();
          expect($noteEl.hasClass('.being-posted')).toEqual(true);
          expect($noteEl.find('.note-text').text()).toEqual(updatedComment);
        });
      });

      it('should show updated comment when comment update is done posting', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          const $noteEl = $notesContainer.find(`#note_${note.id}`);
          $noteEl.find('.js-note-edit').click();
          $noteEl.find('textarea.js-note-text').val(updatedComment);
          $noteEl.find('.js-comment-save-button').click();

          spyOn($, 'ajax').and.callFake((updateOptions) => {
            const updatedNote = Object.assign({}, note);
            updatedNote.note = updatedComment;
            updatedNote.html = `<li class="note note-row-1234 timeline-entry" id="note_1234">
                                  <div class="note-text">${updatedComment}</div>
                                </li>`;
            updateOptions.success(updatedNote);
            const $updatedNoteEl = $notesContainer.find(`#note_${updatedNote.id}`);
            expect($updatedNoteEl.hasClass('.being-posted')).toEqual(false); // Remove being-posted visuals
            expect($updatedNoteEl.find('note-text').text().trim()).toEqual(updatedComment); // Verify if comment text updated
          });
        });
      });

      it('should show flash error message when comment failed to be updated', () => {
        spyOn($, 'ajax').and.callFake((options) => {
          options.success(note);
          const $noteEl = $notesContainer.find(`#note_${note.id}`);
          $noteEl.find('.js-note-edit').click();
          $noteEl.find('textarea.js-note-text').val(updatedComment);
          $noteEl.find('.js-comment-save-button').click();

          spyOn($, 'ajax').and.callFake((updateOptions) => {
            updateOptions.error();
            const $updatedNoteEl = $notesContainer.find(`#note_${note.id}`);
            expect($updatedNoteEl.hasClass('.being-posted')).toEqual(false); // Remove being-posted visuals
            expect($updatedNoteEl.find('note-text').text().trim()).toEqual(sampleComment); // See if comment reverted back to original
            expect($notesContainer.parent().find('.flash-container .flash-text').is(':visible')).toEqual(true); // Flash error message shown
          });
        });
      });
    });
  });
}).call(window);
