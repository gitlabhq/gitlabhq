/* eslint-disable space-before-function-paren, no-var, comma-dangle, dot-notation, quotes, no-undef, no-return-assign, no-underscore-dangle, camelcase, padded-blocks, max-len */

/*= require merge_request_tabs */
//= require breakpoints

(function() {
  describe('MergeRequestTabs', function() {
    var stubLocation;
    stubLocation = function(stubs) {
      var defaults;
      defaults = {
        pathname: '',
        search: '',
        hash: ''
      };
      return $.extend(defaults, stubs);
    };
    fixture.preload('merge_request_tabs.html');
    beforeEach(function() {
      this["class"] = new MergeRequestTabs();
      return this.spies = {
        ajax: spyOn($, 'ajax').and.callFake(function() {}),
        history: spyOn(history, 'replaceState').and.callFake(function() {})
      };
    });
    describe('#activateTab', function() {
      beforeEach(function() {
        fixture.load('merge_request_tabs.html');
        return this.subject = this["class"].activateTab;
      });
      it('shows the first tab when action is show', function() {
        this.subject('show');
        return expect($('#notes')).toHaveClass('active');
      });
      it('shows the notes tab when action is notes', function() {
        this.subject('notes');
        return expect($('#notes')).toHaveClass('active');
      });
      it('shows the commits tab when action is commits', function() {
        this.subject('commits');
        return expect($('#commits')).toHaveClass('active');
      });
      return it('shows the diffs tab when action is diffs', function() {
        this.subject('diffs');
        return expect($('#diffs')).toHaveClass('active');
      });
    });
    return describe('#setCurrentAction', function() {
      beforeEach(function() {
        return this.subject = this["class"].setCurrentAction;
      });
      it('changes from commits', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1/commits'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        return expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
      });
      it('changes from diffs', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1/diffs'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        return expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('changes from diffs.html', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1/diffs.html'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        return expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('changes from notes', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1'
        });
        expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
        return expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('includes search parameters and hash string', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1/diffs',
          search: '?view=parallel',
          hash: '#L15-35'
        });
        return expect(this.subject('show')).toBe('/foo/bar/merge_requests/1?view=parallel#L15-35');
      });
      it('replaces the current history state', function() {
        var new_state;
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1'
        });
        new_state = this.subject('commits');
        return expect(this.spies.history).toHaveBeenCalledWith({
          turbolinks: true,
          url: new_state
        }, document.title, new_state);
      });
      return it('treats "show" like "notes"', function() {
        this["class"]._location = stubLocation({
          pathname: '/foo/bar/merge_requests/1/commits'
        });
        return expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
      });
    });
  });

}).call(this);
