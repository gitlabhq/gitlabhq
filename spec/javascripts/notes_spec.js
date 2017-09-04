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

  const htmlEscape = (comment) => {
    const escapedString = comment.replace(/["&'<>]/g, (a) => {
      const escapedToken = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;',
        '`': '&#x60;'
      }[a];

      return escapedToken;
    });

    return escapedString;
  };

  describe('Notes', function() {
    const FLASH_TYPE_ALERT = 'alert';
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
        this.notes = new Notes('', []);
      });

      it('modifies the Markdown field', function() {
        const changeEvent = document.createEvent('HTMLEvents');
        changeEvent.initEvent('change', true, true);
        $('input[type=checkbox]').attr('checked', true)[0].dispatchEvent(changeEvent);
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
        this.notes = new Notes('', []);

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

    describe('updateNote', () => {
      let sampleComment;
      let noteEntity;
      let $form;
      let $notesContainer;

      beforeEach(() => {
        this.notes = new Notes('', []);
        window.gon.current_username = 'root';
        window.gon.current_user_fullname = 'Administrator';
        sampleComment = 'foo';
        noteEntity = {
          id: 1234,
          html: `<li class="note note-row-1234 timeline-entry" id="note_1234">
                  <div class="note-text">${sampleComment}</div>
                 </li>`,
          note: sampleComment,
          valid: true
        };
        $form = $('form.js-main-target-form');
        $notesContainer = $('ul.main-notes-list');
        $form.find('textarea.js-note-text').val(sampleComment);
      });

      it('updates note and resets edit form', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        spyOn(this.notes, 'revertNoteEditForm');
        spyOn(this.notes, 'setupNewNote');

        $('.js-comment-button').click();
        deferred.resolve(noteEntity);

        const $targetNote = $notesContainer.find(`#note_${noteEntity.id}`);
        const updatedNote = Object.assign({}, noteEntity);
        updatedNote.note = 'bar';
        this.notes.updateNote(updatedNote, $targetNote);

        expect(this.notes.revertNoteEditForm).toHaveBeenCalledWith($targetNote);
        expect(this.notes.setupNewNote).toHaveBeenCalled();
      });
    });

    describe('updateNoteTargetSelector', () => {
      const hash = 'note_foo';
      let $note;

      beforeEach(() => {
        $note = $(`<div id="${hash}"></div>`);
        spyOn($note, 'filter').and.callThrough();
        spyOn($note, 'toggleClass').and.callThrough();
      });

      it('sets target when hash matches', () => {
        spyOn(gl.utils, 'getLocationHash');
        gl.utils.getLocationHash.and.returnValue(hash);

        Notes.updateNoteTargetSelector($note);

        expect($note.filter).toHaveBeenCalledWith(`#${hash}`);
        expect($note.toggleClass).toHaveBeenCalledWith('target', true);
      });

      it('unsets target when hash does not match', () => {
        spyOn(gl.utils, 'getLocationHash');
        gl.utils.getLocationHash.and.returnValue('note_doesnotexist');

        Notes.updateNoteTargetSelector($note);

        expect($note.toggleClass).toHaveBeenCalledWith('target', false);
      });

      it('unsets target when there is not a hash fragment anymore', () => {
        spyOn(gl.utils, 'getLocationHash');
        gl.utils.getLocationHash.and.returnValue(null);

        Notes.updateNoteTargetSelector($note);

        expect($note.toggleClass).toHaveBeenCalledWith('target', false);
      });
    });

    describe('renderNote', () => {
      let notes;
      let note;
      let $notesList;

      beforeEach(() => {
        note = {
          id: 1,
          valid: true,
          note: 'heya',
          html: '<div>heya</div>',
        };
        $notesList = jasmine.createSpyObj('$notesList', [
          'find',
          'append',
        ]);

        notes = jasmine.createSpyObj('notes', [
          'setupNewNote',
          'refresh',
          'collapseLongCommitList',
          'updateNotesCount',
          'putConflictEditWarningInPlace'
        ]);
        notes.taskList = jasmine.createSpyObj('tasklist', ['init']);
        notes.note_ids = [];
        notes.updatedNotesTrackingMap = {};

        spyOn(gl.utils, 'localTimeAgo');
        spyOn(Notes, 'isNewNote').and.callThrough();
        spyOn(Notes, 'isUpdatedNote').and.callThrough();
        spyOn(Notes, 'animateAppendNote').and.callThrough();
        spyOn(Notes, 'animateUpdateNote').and.callThrough();
      });

      describe('when adding note', () => {
        it('should call .animateAppendNote', () => {
          Notes.isNewNote.and.returnValue(true);
          Notes.prototype.renderNote.call(notes, note, null, $notesList);

          expect(Notes.animateAppendNote).toHaveBeenCalledWith(note.html, $notesList);
        });
      });

      describe('when note was edited', () => {
        it('should call .animateUpdateNote', () => {
          Notes.isNewNote.and.returnValue(false);
          Notes.isUpdatedNote.and.returnValue(true);
          const $note = $('<div>');
          $notesList.find.and.returnValue($note);
          const $newNote = $(note.html);
          Notes.animateUpdateNote.and.returnValue($newNote);

          Notes.prototype.renderNote.call(notes, note, null, $notesList);

          expect(Notes.animateUpdateNote).toHaveBeenCalledWith(note.html, $note);
          expect(notes.setupNewNote).toHaveBeenCalledWith($newNote);
        });

        describe('while editing', () => {
          it('should update textarea if nothing has been touched', () => {
            Notes.isNewNote.and.returnValue(false);
            Notes.isUpdatedNote.and.returnValue(true);
            const $note = $(`<div class="is-editing">
              <div class="original-note-content">initial</div>
              <textarea class="js-note-text">initial</textarea>
            </div>`);
            $notesList.find.and.returnValue($note);
            Notes.prototype.renderNote.call(notes, note, null, $notesList);

            expect($note.find('.js-note-text').val()).toEqual(note.note);
          });

          it('should call .putConflictEditWarningInPlace', () => {
            Notes.isNewNote.and.returnValue(false);
            Notes.isUpdatedNote.and.returnValue(true);
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

    describe('isUpdatedNote', () => {
      it('should consider same note text as the same', () => {
        const result = Notes.isUpdatedNote(
          {
            note: 'initial'
          },
          $(`<div>
            <div class="original-note-content">initial</div>
          </div>`)
        );

        expect(result).toEqual(false);
      });

      it('should consider same note with trailing newline as the same', () => {
        const result = Notes.isUpdatedNote(
          {
            note: 'initial\n'
          },
          $(`<div>
            <div class="original-note-content">initial\n</div>
          </div>`)
        );

        expect(result).toEqual(false);
      });

      it('should consider different notes as different', () => {
        const result = Notes.isUpdatedNote(
          {
            note: 'foo'
          },
          $(`<div>
            <div class="original-note-content">bar</div>
          </div>`)
        );

        expect(result).toEqual(true);
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
          'isParallelView',
          'updateNotesCount',
        ]);
        notes.note_ids = [];

        spyOn(gl.utils, 'localTimeAgo');
        spyOn(Notes, 'isNewNote');
        spyOn(Notes, 'animateAppendNote');
        Notes.isNewNote.and.returnValue(true);
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

    describe('putEditFormInPlace', () => {
      it('should call gl.GLForm with GFM parameter passed through', () => {
        spyOn(gl, 'GLForm');

        const $el = jasmine.createSpyObj('$form', ['find', 'closest']);
        $el.find.and.returnValue($('<div>'));
        $el.closest.and.returnValue($('<div>'));

        Notes.prototype.putEditFormInPlace.call({
          getEditFormSelector: () => '',
          enableGFM: true
        }, $el);

        expect(gl.GLForm).toHaveBeenCalledWith(jasmine.any(Object), true);
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
        this.notes = new Notes('', []);
        window.gon.current_username = 'root';
        window.gon.current_user_fullname = 'Administrator';
        $form = $('form.js-main-target-form');
        $notesContainer = $('ul.main-notes-list');
        $form.find('textarea.js-note-text').val(sampleComment);
      });

      it('should show placeholder note while new comment is being posted', () => {
        $('.js-comment-button').click();
        expect($notesContainer.find('.note.being-posted').length > 0).toEqual(true);
      });

      it('should remove placeholder note when new comment is done posting', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.resolve(note);
        expect($notesContainer.find('.note.being-posted').length).toEqual(0);
      });

      it('should show actual note element when new comment is done posting', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.resolve(note);
        expect($notesContainer.find(`#note_${note.id}`).length > 0).toEqual(true);
      });

      it('should reset Form when new comment is done posting', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.resolve(note);
        expect($form.find('textarea.js-note-text').val()).toEqual('');
      });

      it('should show flash error message when new comment failed to be posted', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.reject();
        expect($notesContainer.parent().find('.flash-container .flash-text').is(':visible')).toEqual(true);
      });

      it('should show flash error message when comment failed to be updated', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.resolve(note);
        const $noteEl = $notesContainer.find(`#note_${note.id}`);
        $noteEl.find('.js-note-edit').click();
        $noteEl.find('textarea.js-note-text').val(updatedComment);
        $noteEl.find('.js-comment-save-button').click();

        deferred.reject();
        const $updatedNoteEl = $notesContainer.find(`#note_${note.id}`);
        expect($updatedNoteEl.hasClass('.being-posted')).toEqual(false); // Remove being-posted visuals
        expect($updatedNoteEl.find('.note-text').text().trim()).toEqual(sampleComment); // See if comment reverted back to original
        expect($('.flash-container').is(':visible')).toEqual(true); // Flash error message shown
      });
    });

    describe('postComment with Slash commands', () => {
      const sampleComment = '/assign @root\n/award :100:';
      const note = {
        commands_changes: {
          assignee_id: 1,
          emoji_award: '100'
        },
        errors: {
          commands_only: ['Commands applied']
        },
        valid: false
      };
      let $form;
      let $notesContainer;

      beforeEach(() => {
        this.notes = new Notes('', []);
        window.gon.current_username = 'root';
        window.gon.current_user_fullname = 'Administrator';
        gl.awardsHandler = {
          addAwardToEmojiBar: () => {},
          scrollToAwards: () => {}
        };
        gl.GfmAutoComplete = {
          dataSources: {
            commands: '/root/test-project/autocomplete_sources/commands'
          }
        };
        $form = $('form.js-main-target-form');
        $notesContainer = $('ul.main-notes-list');
        $form.find('textarea.js-note-text').val(sampleComment);
      });

      it('should remove slash command placeholder when comment with slash commands is done posting', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        spyOn(gl.awardsHandler, 'addAwardToEmojiBar').and.callThrough();
        $('.js-comment-button').click();

        expect($notesContainer.find('.system-note.being-posted').length).toEqual(1); // Placeholder shown
        deferred.resolve(note);
        expect($notesContainer.find('.system-note.being-posted').length).toEqual(0); // Placeholder removed
      });
    });

    describe('update comment with script tags', () => {
      const sampleComment = '<script></script>';
      const updatedComment = '<script></script>';
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
        this.notes = new Notes('', []);
        window.gon.current_username = 'root';
        window.gon.current_user_fullname = 'Administrator';
        $form = $('form.js-main-target-form');
        $notesContainer = $('ul.main-notes-list');
        $form.find('textarea.js-note-text').html(sampleComment);
      });

      it('should not render a script tag', () => {
        const deferred = $.Deferred();
        spyOn($, 'ajax').and.returnValue(deferred.promise());
        $('.js-comment-button').click();

        deferred.resolve(note);
        const $noteEl = $notesContainer.find(`#note_${note.id}`);
        $noteEl.find('.js-note-edit').click();
        $noteEl.find('textarea.js-note-text').html(updatedComment);
        $noteEl.find('.js-comment-save-button').click();

        const $updatedNoteEl = $notesContainer.find(`#note_${note.id}`).find('.js-task-list-container');
        expect($updatedNoteEl.find('.note-text').text().trim()).toEqual('');
      });
    });

    describe('getFormData', () => {
      let $form;
      let sampleComment;

      beforeEach(() => {
        this.notes = new Notes('', []);

        $form = $('form');
        sampleComment = 'foobar';
      });

      it('should return form metadata object from form reference', () => {
        $form.find('textarea.js-note-text').val(sampleComment);
        const { formData, formContent, formAction } = this.notes.getFormData($form);

        expect(formData.indexOf(sampleComment) > -1).toBe(true);
        expect(formContent).toEqual(sampleComment);
        expect(formAction).toEqual($form.attr('action'));
      });

      it('should return form metadata with sanitized formContent from form reference', () => {
        spyOn(_, 'escape').and.callFake(htmlEscape);

        sampleComment = '<script>alert("Boom!");</script>';
        $form.find('textarea.js-note-text').val(sampleComment);

        const { formContent } = this.notes.getFormData($form);

        expect(_.escape).toHaveBeenCalledWith(sampleComment);
        expect(formContent).toEqual('&lt;script&gt;alert(&quot;Boom!&quot;);&lt;/script&gt;');
      });
    });

    describe('hasQuickActions', () => {
      beforeEach(() => {
        this.notes = new Notes('', []);
      });

      it('should return true when comment begins with a quick action', () => {
        const sampleComment = '/wip\n/milestone %1.0\n/merge\n/unassign Merging this';
        const hasQuickActions = this.notes.hasQuickActions(sampleComment);

        expect(hasQuickActions).toBeTruthy();
      });

      it('should return false when comment does NOT begin with a quick action', () => {
        const sampleComment = 'Hey, /unassign Merging this';
        const hasQuickActions = this.notes.hasQuickActions(sampleComment);

        expect(hasQuickActions).toBeFalsy();
      });

      it('should return false when comment does NOT have any quick actions', () => {
        const sampleComment = 'Looking good, Awesome!';
        const hasQuickActions = this.notes.hasQuickActions(sampleComment);

        expect(hasQuickActions).toBeFalsy();
      });
    });

    describe('stripQuickActions', () => {
      it('should strip quick actions from the comment which begins with a quick action', () => {
        this.notes = new Notes();
        const sampleComment = '/wip\n/milestone %1.0\n/merge\n/unassign Merging this';
        const stripedComment = this.notes.stripQuickActions(sampleComment);

        expect(stripedComment).toBe('');
      });

      it('should strip quick actions from the comment but leaves plain comment if it is present', () => {
        this.notes = new Notes();
        const sampleComment = '/wip\n/milestone %1.0\n/merge\n/unassign\nMerging this';
        const stripedComment = this.notes.stripQuickActions(sampleComment);

        expect(stripedComment).toBe('Merging this');
      });

      it('should NOT strip string that has slashes within', () => {
        this.notes = new Notes();
        const sampleComment = 'http://127.0.0.1:3000/root/gitlab-shell/issues/1';
        const stripedComment = this.notes.stripQuickActions(sampleComment);

        expect(stripedComment).toBe(sampleComment);
      });
    });

    describe('getQuickActionDescription', () => {
      const availableQuickActions = [
        { name: 'close', description: 'Close this issue', params: [] },
        { name: 'title', description: 'Change title', params: [{}] },
        { name: 'estimate', description: 'Set time estimate', params: [{}] }
      ];

      beforeEach(() => {
        this.notes = new Notes();
      });

      it('should return executing quick action description when note has single quick action', () => {
        const sampleComment = '/close';
        expect(this.notes.getQuickActionDescription(sampleComment, availableQuickActions)).toBe('Applying command to close this issue');
      });

      it('should return generic multiple quick action description when note has multiple quick actions', () => {
        const sampleComment = '/close\n/title [Duplicate] Issue foobar';
        expect(this.notes.getQuickActionDescription(sampleComment, availableQuickActions)).toBe('Applying multiple commands');
      });

      it('should return generic quick action description when available quick actions list is not populated', () => {
        const sampleComment = '/close\n/title [Duplicate] Issue foobar';
        expect(this.notes.getQuickActionDescription(sampleComment)).toBe('Applying command');
      });
    });

    describe('createPlaceholderNote', () => {
      const sampleComment = 'foobar';
      const uniqueId = 'b1234-a4567';
      const currentUsername = 'root';
      const currentUserFullname = 'Administrator';
      const currentUserAvatar = 'avatar_url';

      beforeEach(() => {
        this.notes = new Notes('', []);
      });

      it('should return constructed placeholder element for regular note based on form contents', () => {
        const $tempNote = this.notes.createPlaceholderNote({
          formContent: sampleComment,
          uniqueId,
          isDiscussionNote: false,
          currentUsername,
          currentUserFullname,
          currentUserAvatar,
        });
        const $tempNoteHeader = $tempNote.find('.note-header');

        expect($tempNote.prop('nodeName')).toEqual('LI');
        expect($tempNote.attr('id')).toEqual(uniqueId);
        expect($tempNote.hasClass('being-posted')).toBeTruthy();
        expect($tempNote.hasClass('fade-in-half')).toBeTruthy();
        $tempNote.find('.timeline-icon > a, .note-header-info > a').each(function() {
          expect($(this).attr('href')).toEqual(`/${currentUsername}`);
        });
        expect($tempNote.find('.timeline-icon .avatar').attr('src')).toEqual(currentUserAvatar);
        expect($tempNote.find('.timeline-content').hasClass('discussion')).toBeFalsy();
        expect($tempNoteHeader.find('.hidden-xs').text().trim()).toEqual(currentUserFullname);
        expect($tempNoteHeader.find('.note-headline-light').text().trim()).toEqual(`@${currentUsername}`);
        expect($tempNote.find('.note-body .note-text p').text().trim()).toEqual(sampleComment);
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

      it('should return a escaped user name', () => {
        const currentUserFullnameXSS = 'Foo <script>alert("XSS")</script>';
        const $tempNote = this.notes.createPlaceholderNote({
          formContent: sampleComment,
          uniqueId,
          isDiscussionNote: false,
          currentUsername,
          currentUserFullname: currentUserFullnameXSS,
          currentUserAvatar,
        });
        const $tempNoteHeader = $tempNote.find('.note-header');
        expect($tempNoteHeader.find('.hidden-xs').text().trim()).toEqual('Foo &lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;');
      });
    });

    describe('createPlaceholderSystemNote', () => {
      const sampleCommandDescription = 'Applying command to close this issue';
      const uniqueId = 'b1234-a4567';

      beforeEach(() => {
        this.notes = new Notes('', []);
        spyOn(_, 'escape').and.callFake(htmlEscape);
      });

      it('should return constructed placeholder element for system note based on form contents', () => {
        const $tempNote = this.notes.createPlaceholderSystemNote({
          formContent: sampleCommandDescription,
          uniqueId,
        });

        expect($tempNote.prop('nodeName')).toEqual('LI');
        expect($tempNote.attr('id')).toEqual(uniqueId);
        expect($tempNote.hasClass('being-posted')).toBeTruthy();
        expect($tempNote.hasClass('fade-in-half')).toBeTruthy();
        expect($tempNote.find('.timeline-content i').text().trim()).toEqual(sampleCommandDescription);
      });
    });

    describe('appendFlash', () => {
      beforeEach(() => {
        this.notes = new Notes();
      });

      it('shows a flash message', () => {
        this.notes.addFlash('Error message', FLASH_TYPE_ALERT, this.notes.parentTimeline);

        expect($('.flash-alert').is(':visible')).toBeTruthy();
      });
    });

    describe('clearFlash', () => {
      beforeEach(() => {
        $(document).off('ajax:success');
        this.notes = new Notes();
      });

      it('hides visible flash message', () => {
        this.notes.addFlash('Error message 1', FLASH_TYPE_ALERT, this.notes.parentTimeline);

        this.notes.clearFlash();

        expect($('.flash-alert').is(':visible')).toBeFalsy();
      });
    });
  });
}).call(window);
