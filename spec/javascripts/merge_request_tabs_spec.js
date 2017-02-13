/* eslint-disable no-var, comma-dangle, object-shorthand */

require('~/merge_request_tabs');
require('~/breakpoints');
require('~/lib/utils/common_utils');
require('vendor/jquery.scrollTo');

(function () {
  // TODO: remove this hack!
  // PhantomJS causes spyOn to panic because replaceState isn't "writable"
  var phantomjs;
  try {
    phantomjs = !Object.getOwnPropertyDescriptor(window.history, 'replaceState').writable;
  } catch (err) {
    phantomjs = false;
  }

  describe('MergeRequestTabs', function () {
    var stubLocation = {};
    var setLocation = function (stubs) {
      var defaults = {
        pathname: '',
        search: '',
        hash: ''
      };
      $.extend(stubLocation, defaults, stubs || {});
    };
    preloadFixtures('merge_requests/merge_request_with_task_list.html.raw');

    beforeEach(function () {
      this.class = new gl.MergeRequestTabs({ stubLocation: stubLocation });
      setLocation();

      if (!phantomjs) {
        this.spies = {
          history: spyOn(window.history, 'replaceState').and.callFake(function () {})
        };
      }
    });

    describe('#activateTab', function () {
      beforeEach(function () {
        spyOn($, 'ajax').and.callFake(function () {});
        loadFixtures('merge_requests/merge_request_with_task_list.html.raw');
        this.subject = this.class.activateTab;
      });
      it('shows the first tab when action is show', function () {
        this.subject('show');
        expect($('#notes')).toHaveClass('active');
      });
      it('shows the notes tab when action is notes', function () {
        this.subject('notes');
        expect($('#notes')).toHaveClass('active');
      });
      it('shows the commits tab when action is commits', function () {
        this.subject('commits');
        expect($('#commits')).toHaveClass('active');
      });
      it('shows the diffs tab when action is diffs', function () {
        this.subject('diffs');
        expect($('#diffs')).toHaveClass('active');
      });
    });
    describe('#opensInNewTab', function () {
      var tabUrl;
      var windowTarget = '_blank';

      beforeEach(function () {
        loadFixtures('merge_requests/merge_request_with_task_list.html.raw');

        tabUrl = $('.commits-tab a').attr('href');

        spyOn($.fn, 'attr').and.returnValue(tabUrl);
      });

      describe('meta click', () => {
        beforeEach(function () {
          spyOn(gl.utils, 'isMetaClick').and.returnValue(true);
        });

        it('opens page when commits link is clicked', function () {
          spyOn(window, 'open').and.callFake(function (url, name) {
            expect(url).toEqual(tabUrl);
            expect(name).toEqual(windowTarget);
          });

          this.class.bindEvents();
          document.querySelector('.merge-request-tabs .commits-tab a').click();
        });

        it('opens page when commits badge is clicked', function () {
          spyOn(window, 'open').and.callFake(function (url, name) {
            expect(url).toEqual(tabUrl);
            expect(name).toEqual(windowTarget);
          });

          this.class.bindEvents();
          document.querySelector('.merge-request-tabs .commits-tab a .badge').click();
        });
      });

      it('opens page tab in a new browser tab with Ctrl+Click - Windows/Linux', function () {
        spyOn(window, 'open').and.callFake(function (url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.clickTab({
          metaKey: false,
          ctrlKey: true,
          which: 1,
          stopImmediatePropagation: function () {}
        });
      });
      it('opens page tab in a new browser tab with Cmd+Click - Mac', function () {
        spyOn(window, 'open').and.callFake(function (url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.clickTab({
          metaKey: true,
          ctrlKey: false,
          which: 1,
          stopImmediatePropagation: function () {}
        });
      });
      it('opens page tab in a new browser tab with Middle-click - Mac/PC', function () {
        spyOn(window, 'open').and.callFake(function (url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.clickTab({
          metaKey: false,
          ctrlKey: false,
          which: 2,
          stopImmediatePropagation: function () {}
        });
      });
    });

    describe('#setCurrentAction', function () {
      beforeEach(function () {
        spyOn($, 'ajax').and.callFake(function () {});
        this.subject = this.class.setCurrentAction;
      });
      it('changes from commits', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1/commits'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
      });
      it('changes from diffs', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1/diffs'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('changes from diffs.html', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1/diffs.html'
        });
        expect(this.subject('notes')).toBe('/foo/bar/merge_requests/1');
        expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('changes from notes', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1'
        });
        expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
        expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
      });
      it('includes search parameters and hash string', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1/diffs',
          search: '?view=parallel',
          hash: '#L15-35'
        });
        expect(this.subject('show')).toBe('/foo/bar/merge_requests/1?view=parallel#L15-35');
      });
      it('replaces the current history state', function () {
        var newState;
        setLocation({
          pathname: '/foo/bar/merge_requests/1'
        });
        newState = this.subject('commits');
        if (!phantomjs) {
          expect(this.spies.history).toHaveBeenCalledWith({
            url: newState
          }, document.title, newState);
        }
      });
      it('treats "show" like "notes"', function () {
        setLocation({
          pathname: '/foo/bar/merge_requests/1/commits'
        });
        expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
      });
    });
    describe('#loadDiff', function () {
      it('requires an absolute pathname', function () {
        spyOn($, 'ajax').and.callFake(function (options) {
          expect(options.url).toEqual('/foo/bar/merge_requests/1/diffs.json');
        });
        this.class.loadDiff('/foo/bar/merge_requests/1/diffs');
      });
    });
  });
}).call(this);
