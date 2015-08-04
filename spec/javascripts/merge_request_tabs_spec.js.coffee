#= require merge_request_tabs

describe 'MergeRequestTabs', ->
  stubLocation = (stubs) ->
    defaults = {pathname: '', search: '', hash: ''}
    $.extend(defaults, stubs)

  fixture.preload('merge_request_tabs.html')

  beforeEach ->
    @class = new MergeRequestTabs()
    @spies = {
      ajax:    spyOn($, 'ajax').and.callFake ->
      history: spyOn(history, 'replaceState').and.callFake ->
    }

  describe '#activateTab', ->
    beforeEach ->
      fixture.load('merge_request_tabs.html')
      @subject = @class.activateTab

    it 'shows the first tab when action is show', ->
      @subject('show')
      expect($('#notes')).toHaveClass('active')

    it 'shows the notes tab when action is notes', ->
      @subject('notes')
      expect($('#notes')).toHaveClass('active')

    it 'shows the commits tab when action is commits', ->
      @subject('commits')
      expect($('#commits')).toHaveClass('active')

    it 'shows the diffs tab when action is diffs', ->
      @subject('diffs')
      expect($('#diffs')).toHaveClass('active')

  describe '#setCurrentAction', ->
    beforeEach ->
      @subject = @class.setCurrentAction

    it 'changes from commits', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1/commits')

      expect(@subject('notes')).toBe('/foo/bar/merge_requests/1')
      expect(@subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs')

    it 'changes from diffs', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1/diffs')

      expect(@subject('notes')).toBe('/foo/bar/merge_requests/1')
      expect(@subject('commits')).toBe('/foo/bar/merge_requests/1/commits')

    it 'changes from diffs.html', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1/diffs.html')

      expect(@subject('notes')).toBe('/foo/bar/merge_requests/1')
      expect(@subject('commits')).toBe('/foo/bar/merge_requests/1/commits')

    it 'changes from notes', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1')

      expect(@subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs')
      expect(@subject('commits')).toBe('/foo/bar/merge_requests/1/commits')

    it 'includes search parameters and hash string', ->
      @class._location = stubLocation({
        pathname: '/foo/bar/merge_requests/1/diffs'
        search:   '?view=parallel'
        hash:     '#L15-35'
      })

      expect(@subject('show')).toBe('/foo/bar/merge_requests/1?view=parallel#L15-35')

    it 'replaces the current history state', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1')
      new_state = @subject('commits')

      expect(@spies.history).toHaveBeenCalledWith(
        {turbolinks: true, url: new_state},
        document.title,
        new_state
      )

    it 'treats "show" like "notes"', ->
      @class._location = stubLocation(pathname: '/foo/bar/merge_requests/1/commits')

      expect(@subject('show')).toBe('/foo/bar/merge_requests/1')
