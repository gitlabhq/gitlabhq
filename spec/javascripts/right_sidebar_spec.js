/* eslint-disable space-before-function-paren, no-var, one-var, one-var-declaration-per-line, new-parens, no-return-assign, new-cap, vars-on-top, max-len */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import '~/commons/bootstrap';
import axios from '~/lib/utils/axios_utils';
import Sidebar from '~/right_sidebar';

(function() {
  var $aside, $icon, $labelsIcon, $page, $toggle, assertSidebarState;

  $aside = null;

  $toggle = null;

  $icon = null;

  $page = null;

  $labelsIcon = null;

  assertSidebarState = function(state) {
    var shouldBeCollapsed, shouldBeExpanded;
    shouldBeExpanded = state === 'expanded';
    shouldBeCollapsed = state === 'collapsed';
    expect($aside.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
    expect($page.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
    expect($icon.hasClass('fa-angle-double-right')).toBe(shouldBeExpanded);
    expect($aside.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
    expect($page.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
    return expect($icon.hasClass('fa-angle-double-left')).toBe(shouldBeCollapsed);
  };

  describe('RightSidebar', function() {
    describe('fixture tests', () => {
      var fixtureName = 'issues/open-issue.html.raw';
      preloadFixtures(fixtureName);
      loadJSONFixtures('todos/todos.json');
      let mock;

      beforeEach(function() {
        loadFixtures(fixtureName);
        mock = new MockAdapter(axios);
        new Sidebar(); // eslint-disable-line no-new
        $aside = $('.right-sidebar');
        $page = $('.layout-page');
        $icon = $aside.find('i');
        $toggle = $aside.find('.js-sidebar-toggle');
        return $labelsIcon = $aside.find('.sidebar-collapsed-icon');
      });

      afterEach(() => {
        mock.restore();
      });

      it('should expand/collapse the sidebar when arrow is clicked', function() {
        assertSidebarState('expanded');
        $toggle.click();
        assertSidebarState('collapsed');
        $toggle.click();
        assertSidebarState('expanded');
      });
      it('should float over the page and when sidebar icons clicked', function() {
        $labelsIcon.click();
        return assertSidebarState('expanded');
      });
      it('should collapse when the icon arrow clicked while it is floating on page', function() {
        $labelsIcon.click();
        assertSidebarState('expanded');
        $toggle.click();
        return assertSidebarState('collapsed');
      });

      it('should broadcast todo:toggle event when add todo clicked', function(done) {
        var todos = getJSONFixture('todos/todos.json');
        mock.onPost(/(.*)\/todos$/).reply(200, todos);

        var todoToggleSpy = spyOnEvent(document, 'todo:toggle');

        $('.issuable-sidebar-header .js-issuable-todo').click();

        setTimeout(() => {
          expect(todoToggleSpy.calls.count()).toEqual(1);

          done();
        });
      });

      it('should not hide collapsed icons', () => {
        [].forEach.call(document.querySelectorAll('.sidebar-collapsed-icon'), (el) => {
          expect(el.querySelector('.fa, svg').classList.contains('hidden')).toBeFalsy();
        });
      });
    });

    describe('sidebarToggleClicked', () => {
      const event = jasmine.createSpyObj('event', ['preventDefault']);

      beforeEach(() => {
        spyOn($.fn, 'hasClass').and.returnValue(false);
      });

      afterEach(() => {
        gl.lazyLoader = undefined;
      });

      it('calls loadCheck if lazyLoader is set', () => {
        gl.lazyLoader = jasmine.createSpyObj('lazyLoader', ['loadCheck']);

        Sidebar.prototype.sidebarToggleClicked(event);

        expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
      });

      it('does not throw if lazyLoader is not defined', () => {
        gl.lazyLoader = undefined;

        const toggle = Sidebar.prototype.sidebarToggleClicked.bind(null, event);

        expect(toggle).not.toThrow();
      });
    });
  });
}).call(window);
