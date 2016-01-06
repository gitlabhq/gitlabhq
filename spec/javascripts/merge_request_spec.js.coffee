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

  describe 'reopen/close merge request', ->
    fixture.preload('merge_requests_show.html')
    beforeEach ->
      fixture.load('merge_requests_show.html')
      @merge_request = new MergeRequest({})
    it 'closes a merge request', ->
      $.ajax = (obj) ->
        expect(obj.type).toBe('PUT')
        expect(obj.url).toBe('http://gitlab.com/merge_requests/6/close')
        obj.success saved:true

      $btnClose = $('a.btn-close')
      $btnReopen = $('a.btn-reopen')
      expect($btnReopen).toBeHidden()
      expect($btnClose.text()).toBe('Close')
      expect(typeof $btnClose.prop('disabled')).toBe('undefined')

      $btnClose.trigger('click')

      expect($btnReopen).toBeVisible()

      expect($btnClose).toBeHidden()
      expect($('div.status-box-closed')).toBeVisible()
      expect($('div.status-box-open')).toBeHidden()

    it 'fails to close a merge request with success:false', ->

      $.ajax = (obj) ->
        expect(obj.type).toBe('PUT')
        expect(obj.url).toBe('http://goesnowhere.nothing/whereami')
        obj.success saved:false

      $btnClose = $('a.btn-close')
      $btnReopen = $('a.btn-reopen')
      $btnClose.attr('href','http://goesnowhere.nothing/whereami')
      expect($btnReopen).toBeHidden()
      expect($btnClose.text()).toBe('Close')
      expect(typeof $btnClose.prop('disabled')).toBe('undefined')

      $btnClose.trigger('click')

      expect($btnReopen).toBeHidden()
      expect($btnClose).toBeVisible()
      expect($('div.status-box-closed')).toBeHidden()
      expect($('div.status-box-open')).toBeVisible()
      expect($('div.flash-alert')).toBeVisible()
      expect($('div.flash-alert').text()).toBe('Unable to update this merge request at this time.')

    it 'fails to closes an issue with HTTP error', ->

      $.ajax = (obj) ->
        expect(obj.type).toBe('PUT')
        expect(obj.url).toBe('http://goesnowhere.nothing/whereami')
        obj.error()
      
      $btnClose = $('a.btn-close')
      $btnReopen = $('a.btn-reopen')
      $btnClose.attr('href','http://goesnowhere.nothing/whereami')
      expect($btnReopen).toBeHidden()
      expect($btnClose.text()).toBe('Close')
      expect(typeof $btnClose.prop('disabled')).toBe('undefined')

      $btnClose.trigger('click')
      
      expect($btnReopen).toBeHidden()
      expect($btnClose).toBeVisible()
      expect($('div.status-box-closed')).toBeHidden()
      expect($('div.status-box-open')).toBeVisible()
      expect($('div.flash-alert')).toBeVisible()
      expect($('div.flash-alert').text()).toBe('Unable to update this merge request at this time.')    
    
    it 'reopens a merge request', ->
      $.ajax = (obj) ->
        expect(obj.type).toBe('PUT')
        expect(obj.url).toBe('http://gitlab.com/merge_requests/6/reopen')
        obj.success saved: true

      $btnClose = $('a.btn-close')
      $btnReopen = $('a.btn-reopen')
      expect($btnReopen.text()).toBe('Reopen')

      $btnReopen.trigger('click')

      expect($btnReopen).toBeHidden()
      expect($btnClose).toBeVisible()
      expect($('div.status-box-open')).toBeVisible()
      expect($('div.status-box-closed')).toBeHidden()