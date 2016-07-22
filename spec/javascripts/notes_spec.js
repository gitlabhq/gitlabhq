
/*= require notes */

/*= require gl_form */
window.gon || (window.gon = {});

window.disableButtonIfEmptyField = function() {
  return null;
};

describe('Notes', function() {
  return describe('task lists', function() {
    fixture.preload('issue_note.html');
    beforeEach(function() {
      fixture.load('issue_note.html');
      $('form').on('submit', function(e) {
        return e.preventDefault();
      });
      return this.notes = new Notes();
    });
    it('modifies the Markdown field', function() {
      $('input[type=checkbox]').attr('checked', true).trigger('change');
      return expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
    });
    return it('submits the form on tasklist:changed', function() {
      var submitted;
      submitted = false;
      $('form').on('submit', function(e) {
        submitted = true;
        return e.preventDefault();
      });
      $('.js-task-list-field').trigger('tasklist:changed');
      return expect(submitted).toBe(true);
    });
  });
});
