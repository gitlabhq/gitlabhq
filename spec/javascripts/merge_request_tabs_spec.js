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
  const stubLocation = {};
  const setLocation = function(stubs) {
    const defaults = {
      pathname: '',
      search: '',
      hash: '',
    };
    $.extend(stubLocation, defaults, stubs || {});
  };

  preloadFixtures(
    'merge_requests/merge_request_with_task_list.html',
    'merge_requests/diff_comment.html',
  );

  beforeEach(function() {
    mrPageMock = initMrPage();
    this.class = new MergeRequestTabs({ stubLocation });
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
    const windowTarget = '_blank';
    let clickTabParams;
    let tabUrl;

    beforeEach(function() {
      loadFixtures('merge_requests/merge_request_with_task_list.html');

      tabUrl = $('.commits-tab a').attr('href');

      clickTabParams = {
        metaKey: false,
        ctrlKey: false,
        which: 1,
        stopImmediatePropagation() {},
        preventDefault() {},
        currentTarget: {
          getAttribute(attr) {
            return attr === 'href' ? tabUrl : null;
          },
        },
      };
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

        expect(window.open).toHaveBeenCalled();
      });

      it('opens page when commits badge is clicked', function() {
        spyOn(window, 'open').and.callFake(function(url, name) {
          expect(url).toEqual(tabUrl);
          expect(name).toEqual(windowTarget);
        });

        this.class.bindEvents();
        $('.merge-request-tabs .commits-tab a .badge').trigger(metakeyEvent);

        expect(window.open).toHaveBeenCalled();
      });
    });

    it('opens page tab in a new browser tab with Ctrl+Click - Windows/Linux', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({ ...clickTabParams, metaKey: true });

      expect(window.open).toHaveBeenCalled();
    });

    it('opens page tab in a new browser tab with Cmd+Click - Mac', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({ ...clickTabParams, ctrlKey: true });

      expect(window.open).toHaveBeenCalled();
    });

    it('opens page tab in a new browser tab with Middle-click - Mac/PC', function() {
      spyOn(window, 'open').and.callFake(function(url, name) {
        expect(url).toEqual(tabUrl);
        expect(name).toEqual(windowTarget);
      });

      this.class.clickTab({ ...clickTabParams, which: 2 });

      expect(window.open).toHaveBeenCalled();
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
      setLocation({
        pathname: '/foo/bar/merge_requests/1',
      });
      const newState = this.subject('commits');

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

    it('does not add container-limited when fluid layout is prefered', function() {
      $('.content-wrapper .container-fluid').removeClass('container-limited');

      this.class.expandViewContainer(false);

      expect($('.content-wrapper')).not.toContainElement('.container-limited');
    });

    it('does remove container-limited from breadcrumbs', function() {
      $('.container-limited').addClass('breadcrumbs');
      this.class.expandViewContainer();

      expect($('.content-wrapper')).toContainElement('.container-limited');
    });
  });

  describe('tabShown', function() {
    const mainContent = document.createElement('div');
    const tabContent = document.createElement('div');

    beforeEach(function() {
      spyOn(mainContent, 'getBoundingClientRect').and.returnValue({ top: 10 });
      spyOn(tabContent, 'getBoundingClientRect').and.returnValue({ top: 100 });
      spyOn(document, 'querySelector').and.callFake(function(selector) {
        return selector === '.content-wrapper' ? mainContent : tabContent;
      });
      this.class.currentAction = 'commits';
    });

    it('calls window scrollTo with options if document has scrollBehavior', function() {
      document.documentElement.style.scrollBehavior = '';

      spyOn(window, 'scrollTo');

      this.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.calls.first().args[0]).toEqual({ top: 39, behavior: 'smooth' });
    });

    it('calls window scrollTo with two args if document does not have scrollBehavior', function() {
      spyOnProperty(document.documentElement, 'style', 'get').and.returnValue({});

      spyOn(window, 'scrollTo');

      this.class.tabShown('commits', 'foobar');

      expect(window.scrollTo.calls.first().args).toEqual([0, 39]);
    });
  });
});
