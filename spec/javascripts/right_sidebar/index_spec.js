import '~/commons/bootstrap';
import RightSidebar from '~/right_sidebar/index';

describe('RightSidebar', () => {
  describe('fixture tests', () => {
    let $aside;
    let $toggle;
    let $icon;
    let $page;
    let $labelsIcon;
    const fixtureName = 'issues/open-issue.html.raw';

    preloadFixtures(fixtureName);
    loadJSONFixtures('todos/todos.json');

    function assertSidebarState(state) {
      const shouldBeExpanded = state === 'expanded';
      const shouldBeCollapsed = state === 'collapsed';

      expect($aside.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
      expect($page.hasClass('right-sidebar-expanded')).toBe(shouldBeExpanded);
      expect($icon.hasClass('fa-angle-double-right')).toBe(shouldBeExpanded);
      expect($aside.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
      expect($page.hasClass('right-sidebar-collapsed')).toBe(shouldBeCollapsed);
      expect($icon.hasClass('fa-angle-double-left')).toBe(shouldBeCollapsed);
    }

    beforeEach(() => {
      loadFixtures(fixtureName);
      new RightSidebar(); // eslint-disable-line no-new
      $aside = $('.right-sidebar');
      $page = $('.page-with-sidebar');
      $icon = $aside.find('i');
      $toggle = $aside.find('.js-sidebar-toggle');
      $labelsIcon = $aside.find('.sidebar-collapsed-icon');
    });

    it('should expand/collapse the sidebar when arrow is clicked', () => {
      assertSidebarState('expanded');
      $toggle.click();
      assertSidebarState('collapsed');
      $toggle.click();
      assertSidebarState('expanded');
    });

    it('should float over the page and when sidebar icons clicked', () => {
      $labelsIcon.click();
      assertSidebarState('expanded');
    });

    it('should collapse when the icon arrow clicked while it is floating on page', () => {
      $labelsIcon.click();
      assertSidebarState('expanded');
      $toggle.click();
      assertSidebarState('collapsed');
    });

    it('should broadcast todo:toggle event when add todo clicked', () => {
      const todos = getJSONFixture('todos/todos.json');
      spyOn(jQuery, 'ajax').and.callFake(() => {
        const d = $.Deferred();
        const response = todos;
        d.resolve(response);
        return d.promise();
      });

      const todoToggleSpy = spyOnEvent(document, 'todo:toggle');

      $('.issuable-sidebar-header .js-issuable-todo').click();

      expect(todoToggleSpy.calls.count()).toEqual(1);
    });

    it('should not hide collapsed icons', () => {
      // todo replace foreach.call
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

      RightSidebar.prototype.sidebarToggleClicked(event);

      expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
    });

    it('does not throw if lazyLoader is not defined', () => {
      gl.lazyLoader = undefined;

      const toggle = RightSidebar.prototype.sidebarToggleClicked.bind(null, event);

      expect(toggle).not.toThrow();
    });
  });
});
