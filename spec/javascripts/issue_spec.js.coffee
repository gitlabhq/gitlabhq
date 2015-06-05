#= require issue

describe 'Issue', ->
  describe 'task lists', ->
    fixture.preload('issues_show.html')

    beforeEach ->
      fixture.load('issues_show.html')
      @issue = new Issue()

    it 'modifies the Markdown field', ->
      spyOn(jQuery, 'ajax').and.stub()
      $('input[type=checkbox]').attr('checked', true).trigger('change')
      expect($('.js-task-list-field').val()).toBe('- [x] Task List Item')

    it 'submits an ajax request on tasklist:changed', ->
      spyOn(jQuery, 'ajax').and.callFake (req) ->
        expect(req.type).toBe('PATCH')
        expect(req.url).toBe('/foo')
        expect(req.data.issue.description).not.toBe(null)

      $('.js-task-list-field').trigger('tasklist:changed')
