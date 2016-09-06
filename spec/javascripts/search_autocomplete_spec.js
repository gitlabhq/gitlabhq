
/*= require gl_dropdown */


/*= require search_autocomplete */


/*= require jquery */


/*= require lib/utils/common_utils */


/*= require lib/utils/type_utility */


/*= require fuzzaldrin-plus */

(function() {
  var addBodyAttributes, assertLinks, dashboardIssuesPath, dashboardMRsPath, groupIssuesPath, groupMRsPath, groupName, mockDashboardOptions, mockGroupOptions, mockProjectOptions, projectIssuesPath, projectMRsPath, projectName, userId, widget;

  widget = null;

  userId = 1;

  window.gon || (window.gon = {});

  window.gon.current_user_id = userId;

  dashboardIssuesPath = '/dashboard/issues';

  dashboardMRsPath = '/dashboard/merge_requests';

  projectIssuesPath = '/gitlab-org/gitlab-ce/issues';

  projectMRsPath = '/gitlab-org/gitlab-ce/merge_requests';

  groupIssuesPath = '/groups/gitlab-org/issues';

  groupMRsPath = '/groups/gitlab-org/merge_requests';

  projectName = 'GitLab Community Edition';

  groupName = 'Gitlab Org';

  addBodyAttributes = function(section) {
    var $body;
    if (section == null) {
      section = 'dashboard';
    }
    $body = $('body');
    $body.removeAttr('data-page');
    $body.removeAttr('data-project');
    $body.removeAttr('data-group');
    switch (section) {
      case 'dashboard':
        return $body.data('page', 'root:index');
      case 'group':
        $body.data('page', 'groups:show');
        return $body.data('group', 'gitlab-org');
      case 'project':
        $body.data('page', 'projects:show');
        return $body.data('project', 'gitlab-ce');
    }
  };

  mockDashboardOptions = function() {
    window.gl || (window.gl = {});
    return window.gl.dashboardOptions = {
      issuesPath: dashboardIssuesPath,
      mrPath: dashboardMRsPath
    };
  };

  mockProjectOptions = function() {
    window.gl || (window.gl = {});
    return window.gl.projectOptions = {
      'gitlab-ce': {
        issuesPath: projectIssuesPath,
        mrPath: projectMRsPath,
        projectName: projectName
      }
    };
  };

  mockGroupOptions = function() {
    window.gl || (window.gl = {});
    return window.gl.groupOptions = {
      'gitlab-org': {
        issuesPath: groupIssuesPath,
        mrPath: groupMRsPath,
        projectName: groupName
      }
    };
  };

  assertLinks = function(list, issuesPath, mrsPath) {
    var a1, a2, a3, a4, issuesAssignedToMeLink, issuesIHaveCreatedLink, mrsAssignedToMeLink, mrsIHaveCreatedLink;
    issuesAssignedToMeLink = issuesPath + "/?assignee_id=" + userId;
    issuesIHaveCreatedLink = issuesPath + "/?author_id=" + userId;
    mrsAssignedToMeLink = mrsPath + "/?assignee_id=" + userId;
    mrsIHaveCreatedLink = mrsPath + "/?author_id=" + userId;
    a1 = "a[href='" + issuesAssignedToMeLink + "']";
    a2 = "a[href='" + issuesIHaveCreatedLink + "']";
    a3 = "a[href='" + mrsAssignedToMeLink + "']";
    a4 = "a[href='" + mrsIHaveCreatedLink + "']";
    expect(list.find(a1).length).toBe(1);
    expect(list.find(a1).text()).toBe('Issues assigned to me');
    expect(list.find(a2).length).toBe(1);
    expect(list.find(a2).text()).toBe("Issues I've created");
    expect(list.find(a3).length).toBe(1);
    expect(list.find(a3).text()).toBe('Merge requests assigned to me');
    expect(list.find(a4).length).toBe(1);
    return expect(list.find(a4).text()).toBe("Merge requests I've created");
  };

  describe('Search autocomplete dropdown', function() {
    fixture.preload('search_autocomplete.html');
    beforeEach(function() {
      fixture.load('search_autocomplete.html');
      return widget = new SearchAutocomplete;
    });
    it('should show Dashboard specific dropdown menu', function() {
      var list;
      addBodyAttributes();
      mockDashboardOptions();
      widget.searchInput.focus();
      list = widget.wrap.find('.dropdown-menu').find('ul');
      return assertLinks(list, dashboardIssuesPath, dashboardMRsPath);
    });
    it('should show Group specific dropdown menu', function() {
      var list;
      addBodyAttributes('group');
      mockGroupOptions();
      widget.searchInput.focus();
      list = widget.wrap.find('.dropdown-menu').find('ul');
      return assertLinks(list, groupIssuesPath, groupMRsPath);
    });
    it('should show Project specific dropdown menu', function() {
      var list;
      addBodyAttributes('project');
      mockProjectOptions();
      widget.searchInput.focus();
      list = widget.wrap.find('.dropdown-menu').find('ul');
      return assertLinks(list, projectIssuesPath, projectMRsPath);
    });
    return it('should not show category related menu if there is text in the input', function() {
      var link, list;
      addBodyAttributes('project');
      mockProjectOptions();
      widget.searchInput.val('help');
      widget.searchInput.focus();
      list = widget.wrap.find('.dropdown-menu').find('ul');
      link = "a[href='" + projectIssuesPath + "/?assignee_id=" + userId + "']";
      return expect(list.find(link).length).toBe(0);
    });
  });

}).call(this);
