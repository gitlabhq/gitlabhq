/* eslint-disable */

/*= require right_sidebar */
/*= require jquery */
/*= require js.cookie */

/*= require extensions/jquery.js */

(function() {
  var $aside, $icon, $labelsIcon, $page, $toggle, assertSidebarState;

  this.sidebar = null;

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
    fixture.preload('right_sidebar.html');
    beforeEach(function() {
      fixture.load('right_sidebar.html');
      this.sidebar = new Sidebar;
      $aside = $('.right-sidebar');
      $page = $('.page-with-sidebar');
      $icon = $aside.find('i');
      $toggle = $aside.find('.js-sidebar-toggle');
      return $labelsIcon = $aside.find('.sidebar-collapsed-icon');
    });
    it('should expand the sidebar when arrow is clicked', function() {
      $toggle.click();
      return assertSidebarState('expanded');
    });
    it('should collapse the sidebar when arrow is clicked', function() {
      $toggle.click();
      assertSidebarState('expanded');
      $toggle.click();
      return assertSidebarState('collapsed');
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

    it('should broadcast todo:toggle event when add todo clicked', function() {
      spyOn(jQuery, 'ajax').and.callFake(function() {
        var d = $.Deferred();
        var response = fixture.load('todos.json');
        d.resolve(response);
        return d.promise();
      });

      var todoToggleSpy = spyOnEvent(document, 'todo:toggle');

      $('.js-issuable-todo').click();

      expect(todoToggleSpy.calls.count()).toEqual(1);
    })
  });

}).call(this);
