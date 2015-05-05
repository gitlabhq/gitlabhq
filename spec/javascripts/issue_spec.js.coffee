#= require jquery
#= require jasmine-fixture
#= require issue

describe 'Issue', ->
  describe 'task lists', ->
    selectors = {
      container: '.issue-details .description.js-task-list-container'
      item:      '.wiki ul.task-list li.task-list-item input.task-list-item-checkbox[type=checkbox] {Task List Item}'
      textarea:  '.wiki textarea.js-task-list-field{- [ ] Task List Item}'
      form:      'form.js-issue-update[action="/foo"]'
      close:     'a.btn-close'
    }

    beforeEach ->
      $container = affix(selectors.container)

      # # These two elements are siblings inside the container
      $container.find('.js-task-list-container').append(affix(selectors.item))
      $container.find('.js-task-list-container').append(affix(selectors.textarea))

      # Task lists don't get initialized unless this button exists. Not ideal.
      $container.append(affix(selectors.close))

      # This form is used to get the `update` URL. Not ideal.
      $container.append(affix(selectors.form))

      @issue = new Issue()

    it 'submits an ajax request on tasklist:changed', ->
      spyOn($, 'ajax').and.callFake (req) ->
        expect(req.type).toBe('PATCH')
        expect(req.url).toBe('/foo')
        expect(req.data.issue.description).not.toBe(null)

      $('.js-task-list-field').trigger('tasklist:changed')
