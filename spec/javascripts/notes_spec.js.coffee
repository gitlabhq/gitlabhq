#= require notes

window.gon = {}
window.disableButtonIfEmptyField = -> null

describe 'Notes', ->
  describe 'task lists', ->
    fixture.preload('issue_note.html')

    beforeEach ->
      fixture.load('issue_note.html')
      $('form').on 'submit', (e) -> e.preventDefault()

      @notes = new Notes()

    it 'modifies the Markdown field', ->
      $('input[type=checkbox]').attr('checked', true).trigger('change')
      expect($('.js-task-list-field').val()).toBe('- [x] Task List Item')

    it 'submits the form on tasklist:changed', ->
      submitted = false
      $('form').on 'submit', (e) -> submitted = true; e.preventDefault()

      $('.js-task-list-field').trigger('tasklist:changed')
      expect(submitted).toBe(true)
