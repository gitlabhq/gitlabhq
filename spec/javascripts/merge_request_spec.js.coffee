#= require merge_request

describe 'MergeRequest', ->
  describe 'task lists', ->
    fixture.preload('merge_requests_show.html')

    beforeEach ->
      fixture.load('merge_requests_show.html')
      @merge = new MergeRequest({})

    it 'modifies the Markdown field', ->
      spyOn(jQuery, 'ajax').and.stub()

      $('input[type=checkbox]').attr('checked', true).trigger('change')
      expect($('.js-task-list-field').val()).toBe('- [x] Task List Item')

    it 'submits an ajax request on tasklist:changed', ->
      spyOn(jQuery, 'ajax').and.callFake (req) ->
        expect(req.type).toBe('PATCH')
        expect(req.url).toBe('/foo')
        expect(req.data.merge_request.description).not.toBe(null)

      $('.js-task-list-field').trigger('tasklist:changed')
