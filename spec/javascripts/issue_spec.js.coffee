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
describe 'reopen/close issue', ->
  fixture.preload('issues_show.html')
  beforeEach ->
    fixture.load('issues_show.html')
    @issue = new Issue()
  it 'closes an issue', ->
    spyOn(jQuery, 'ajax').and.callFake (req) ->
      expect(req.type).toBe('PUT')
      expect(req.url).toBe('http://gitlab.com/issues/6/close')
      req.success saved: true
    
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

  it 'fails to close an issue with success:false', ->

    spyOn(jQuery, 'ajax').and.callFake (req) ->
      expect(req.type).toBe('PUT')
      expect(req.url).toBe('http://goesnowhere.nothing/whereami')
      req.success saved: false
    
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
    expect($('div.flash-alert').text()).toBe('Unable to update this issue at this time.')

  it 'fails to closes an issue with HTTP error', ->

    spyOn(jQuery, 'ajax').and.callFake (req) ->
      expect(req.type).toBe('PUT')
      expect(req.url).toBe('http://goesnowhere.nothing/whereami')
      req.error()
    
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
    expect($('div.flash-alert').text()).toBe('Unable to update this issue at this time.')

  it 'reopens an issue', ->
    spyOn(jQuery, 'ajax').and.callFake (req) ->
      expect(req.type).toBe('PUT')
      expect(req.url).toBe('http://gitlab.com/issues/6/reopen')
      req.success saved: true

    $btnClose = $('a.btn-close')
    $btnReopen = $('a.btn-reopen')
    expect($btnReopen.text()).toBe('Reopen')

    $btnReopen.trigger('click')

    expect($btnReopen).toBeHidden()
    expect($btnClose).toBeVisible()
    expect($('div.status-box-open')).toBeVisible()
    expect($('div.status-box-closed')).toBeHidden()