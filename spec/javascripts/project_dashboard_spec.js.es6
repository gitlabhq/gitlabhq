require('~/sidebar');

(() => {
  describe('Project dashboard page', () => {
    let $pageWithSidebar = null;
    let $sidebarToggle = null;
    let sidebar = null;
    const fixtureTemplate = 'projects/dashboard.html.raw';

    const assertSidebarStateExpanded = (shouldBeExpanded) => {
      expect(sidebar.isExpanded).toBe(shouldBeExpanded);
      expect($pageWithSidebar.hasClass('page-sidebar-expanded')).toBe(shouldBeExpanded);
    };

    preloadFixtures(fixtureTemplate);
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      $pageWithSidebar = $('.page-with-sidebar');
      $sidebarToggle = $('.toggle-nav-collapse');

      // otherwise instantiating the Sidebar for the second time
      // won't do anything, as the Sidebar is a singleton class
      gl.Sidebar.singleton = null;
      sidebar = new gl.Sidebar();
    });

    it('can show the sidebar when the toggler is clicked', () => {
      assertSidebarStateExpanded(false);
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);
    });

    it('should dismiss the sidebar when clone button clicked', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      const cloneButton = $('.project-clone-holder a.clone-dropdown-btn');
      cloneButton.click();
      assertSidebarStateExpanded(false);
    });

    it('should dismiss the sidebar when download button clicked', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      const downloadButton = $('.project-action-button .btn:has(i.fa-download)');
      downloadButton.click();
      assertSidebarStateExpanded(false);
    });

    it('should dismiss the sidebar when add button clicked', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      const addButton = $('.project-action-button .btn:has(i.fa-plus)');
      addButton.click();
      assertSidebarStateExpanded(false);
    });

    it('should dismiss the sidebar when notification button clicked', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      const notifButton = $('.js-notification-toggle-btns .notifications-btn');
      notifButton.click();
      assertSidebarStateExpanded(false);
    });

    it('should dismiss the sidebar when clicking on the body', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      $('body').click();
      assertSidebarStateExpanded(false);
    });

    it('should dismiss the sidebar when clicking on the project description header', () => {
      $sidebarToggle.click();
      assertSidebarStateExpanded(true);

      $('.project-home-panel').click();
      assertSidebarStateExpanded(false);
    });
  });
})();
