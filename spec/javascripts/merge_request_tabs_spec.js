/* eslint-disable no-var, object-shorthand */
import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MergeRequestTabs from '~/merge_request_tabs';
import '~/commit/pipelines/pipelines_bundle';
import '~/breakpoints';
import '~/lib/utils/common_utils';
import 'vendor/jquery.scrollTo';
import initMrPage from './helpers/init_vue_mr_page_helper';

describe('MergeRequestTabs', function() {
  let mrPageMock;
  var stubLocation = {};
  var setLocation = function(stubs) {
    var defaults = {
      pathname: '',
      search: '',
      hash: '',
    };
    $.extend(stubLocation, defaults, stubs || {});
  };

  preloadFixtures(
    'merge_requests/merge_request_with_task_list.html.raw',
    'merge_requests/diff_comment.html.raw',
  );

  beforeEach(function() {
    mrPageMock = initMrPage();
    this.class = new MergeRequestTabs({ stubLocation: stubLocation });
    setLocation();

    this.spies = {
      history: spyOn(window.history, 'replaceState').and.callFake(function() {}),
    };
  });

  afterEach(function() {
    this.class.unbindEvents();
    this.class.destroyPipelinesView();
    mrPageMock.restore();
    $('.js-merge-request-test').remove();
  });

  describe('opensInNewTab', function() {
    var tabUrl;
    var windowTarget = '_blank';

    beforeEach(function() {
      loadFixtures('merge_requests/merge_request_with_task_list.html.raw');

      tabUrl = $('.commits-tab a').attr('href');
    });

    describe('meta click', () => {
      let metakeyEvent;
      beforeEach(function() {
        metakeyEvent = $.Event('click', { keyCode: 91, ctrlKey: true });
      });

      it('opens page when commits link is clicked', function() {
        spyOn(window, 'open').and.callFake(function(url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.bindEvents();
        $('.merge-request-tabs .commits-tab a').trigger(metakeyEvent);
      });

      it('opens page when commits badge is clicked', function() {
        spyOn(window, 'open').and.callFake(function(url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.bindEvents();
        $('.merge-request-tabs .commits-tab a .badge').trigger(metakeyEvent);
      });
    });

    it('opens page tab in a new browser tab with Ctrl+Click - Windows/Linux', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({
        metaKey: false,
        ctrlKey: true,
        which: 1,
        stopImmediatePropagation: function() {},
      });
    });

    it('opens page tab in a new browser tab with Cmd+Click - Mac', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({
        metaKey: true,
        ctrlKey: false,
        which: 1,
        stopImmediatePropagation: function() {},
      });
    });

    it('opens page tab in a new browser tab with Middle-click - Mac/PC', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({
        metaKey: false,
        ctrlKey: false,
        which: 2,
        stopImmediatePropagation: function() {},
      });
    });
  });

  describe('setCurrentAction', function() {
    let mock;

    beforeEach(function() {
      mock = new MockAdapter(axios);
      mock.onAny().reply({ data: {} });
      this.subject = this.class.setCurrentAction;
    });

    afterEach(() => {
      mock.restore();
    });

    it('changes from commits', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1/commits',
      });

      expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
      expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
    });

    it('changes from diffs', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1/diffs',
      });

      expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
      expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
    });

    it('changes from diffs.html', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1/diffs.html',
      });

      expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
      expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
    });

    it('changes from notes', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1',
      });

      expect(this.subject('diffs')).toBe('/foo/bar/merge_requests/1/diffs');
      expect(this.subject('commits')).toBe('/foo/bar/merge_requests/1/commits');
    });

    it('includes search parameters and hash string', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1/diffs',
        search: '?view=parallel',
        hash: '#L15-35',
      });

      expect(this.subject('show')).toBe('/foo/bar/merge_requests/1?view=parallel#L15-35');
    });

    it('replaces the current history state', function() {
      var newState;
      setLocation({
        pathname: '/foo/bar/merge_requests/1',
      });
      newState = this.subject('commits');

      expect(this.spies.history).toHaveBeenCalledWith(
        {
          url: newState,
        },
        document.title,
        newState,
      );
    });

    it('treats "show" like "notes"', function() {
      setLocation({
        pathname: '/foo/bar/merge_requests/1/commits',
      });

      expect(this.subject('show')).toBe('/foo/bar/merge_requests/1');
    });
  });

  describe('expandViewContainer', function() {
    beforeEach(() => {
      $('body').append(
        '<div class="content-wrapper"><div class="container-fluid container-limited"></div></div>',
      );
    });

    afterEach(() => {
      $('.content-wrapper').remove();
    });

    it('removes container-limited from containers', function() {
      this.class.expandViewContainer();

      expect($('.content-wrapper')).not.toContainElement('.container-limited');
    });

    it('does remove container-limited from breadcrumbs', function() {
      $('.container-limited').addClass('breadcrumbs');
      this.class.expandViewContainer();

      expect($('.content-wrapper')).toContainElement('.container-limited');
    });
  });
});
