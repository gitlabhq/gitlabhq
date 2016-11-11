/* eslint-disable */
/*= require notes */
/*= require autosize */
/*= require gl_form */
/*= require lib/utils/text_utility */

(function() {
  window.gon || (window.gon = {});

  window.disableButtonIfEmptyField = function() {
    return null;
  };

  describe('Notes', function() {
    describe('task lists', function() {
      fixture.preload('issue_note.html');

      beforeEach(function() {
        fixture.load('issue_note.html');
        $('form').on('submit', function(e) {
          e.preventDefault();
        });
        this.notes = new Notes();
      });

      it('modifies the Markdown field', function() {
        $('input[type=checkbox]').attr('checked', true).trigger('change');
        expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });

      it('submits the form on tasklist:changed', function() {
        var submitted = false;
        $('form').on('submit', function(e) {
          submitted = true;
          e.preventDefault();
        });

        $('.js-task-list-field').trigger('tasklist:changed');
        expect(submitted).toBe(true);
      });
    });

    describe('comments', function() {
      var commentsTemplate = 'comments.html';
      var textarea = '.js-note-text';
      fixture.preload(commentsTemplate);

      beforeEach(function() {
        fixture.load(commentsTemplate);
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
      })
    });
  });

}).call(this);
