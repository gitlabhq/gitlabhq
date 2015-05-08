#= require jquery
#= require jasmine-fixture
#= require notes

window.gon = {}
window.disableButtonIfEmptyField = -> null

describe 'Notes', ->
  describe 'task lists', ->
    selectors = {
      container: 'li.note .js-task-list-container'
      item:      '.note-text ul.task-list li.task-list-item input.task-list-item-checkbox[type=checkbox] {Task List Item}'
      textarea:  '.note-edit-form form textarea.js-task-list-field{- [ ] Task List Item}'
    }

    beforeEach ->
      $container = affix(selectors.container)

      # These two elements are siblings inside the container
      $container.find('.js-task-list-container').append(affix(selectors.item))
      $container.find('.js-task-list-container').append(affix(selectors.textarea))

      @notes = new Notes()

    it 'submits the form on tasklist:changed', ->
      submitted = false
      $('form').on 'submit', (e) -> submitted = true; e.preventDefault()

      $('.js-task-list-field').trigger('tasklist:changed')
      expect(submitted).toBe(true)
