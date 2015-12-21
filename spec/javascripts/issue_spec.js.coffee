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
    $.ajax = (obj) ->
      expect(obj.type).toBe('PUT')
      expect(obj.url).toBe('http://gitlab/issues/6/close')
      obj.success saved: true
    
    # setup
    $btnClose = $('a.btn-close')
    $btnReopen = $('a.btn-reopen')
    expect($btnReopen.toBeHidden())
    expect($btnClose.text()).toBe('Close')
    expect(typeof $btnClose.prop('disabled')).toBe('undefined')

    # excerize
    $btnClose.trigger('click')
    
    # verify
    expect($btnClose.toBeHidden())
    expect($btnReopen.toBeVisible())
    expect($('div.issue-box-open').toBeVisible())
    expect($('div.issue-box-closed').toBeHidden())

    # teardown
  it 'reopens an issue', ->
    $.ajax = (obj) ->
      expect(obj.type).toBe('PUT')
      expect(obj.url).toBe('http://gitlab/issues/6/reopen')
      obj.success saved: true

    # setup
    $btnClose = $('a.btn-close')
    $btnReopen = $('a.btn-reopen')
    expect($btnReopen.text()).toBe('Reopen')

    # excerize
    $btnReopen.trigger('click')

    # verify
    expect($btnReopen.toBeHidden())
    expect($btnClose.toBeVisible())
    expect($('div.issue-box-open').toBeVisible())
    expect($('div.issue-box-closed').toBeHidden())

    # teardown