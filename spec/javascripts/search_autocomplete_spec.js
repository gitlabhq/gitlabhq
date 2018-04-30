/* eslint-disable space-before-function-paren, max-len, no-var, one-var, one-var-declaration-per-line, no-unused-expressions, consistent-return, no-param-reassign, default-case, no-return-assign, comma-dangle, object-shorthand, prefer-template, quotes, new-parens, vars-on-top, new-cap, max-len */

import $ from 'jquery';
import '~/gl_dropdown';
import SearchAutocomplete from '~/search_autocomplete';
import '~/lib/utils/common_utils';

describe('Search autocomplete dropdown', () => {
  var assertLinks,
    dashboardIssuesPath,
    dashboardMRsPath,
    groupIssuesPath,
    groupMRsPath,
    groupName,
    mockDashboardOptions,
    mockGroupOptions,
    mockProjectOptions,
    projectIssuesPath,
    projectMRsPath,
    projectName,
    userId,
    widget;
  var userName = 'root';

  widget = null;

  userId = 1;

  dashboardIssuesPath = '/dashboard/issues';

  dashboardMRsPath = '/dashboard/merge_requests';

  projectIssuesPath = '/gitlab-org/gitlab-ce/issues';

  projectMRsPath = '/gitlab-org/gitlab-ce/merge_requests';

  groupIssuesPath = '/groups/gitlab-org/issues';

  groupMRsPath = '/groups/gitlab-org/merge_requests';

  projectName = 'GitLab Community Edition';

  groupName = 'Gitlab Org';

  const removeBodyAttributes = function() {
    const $body = $('body');

    $body.removeAttr('data-page');
    $body.removeAttr('data-project');
    $body.removeAttr('data-group');
  };

  // Add required attributes to body before starting the test.
  // section would be dashboard|group|project
  const addBodyAttributes = function(section) {
    if (section == null) {
      section = 'dashboard';
    }

    const $body = $('body');
    removeBodyAttributes();
    switch (section) {
      case 'dashboard':
        return $body.attr('data-page', 'root:index');
      case 'group':
        $body.attr('data-page', 'groups:show');
        return $body.data('group', 'gitlab-org');
      case 'project':
        $body.attr('data-page', 'projects:show');
        return $body.data('project', 'gitlab-ce');
    }
  };

  const disableProjectIssues = function() {
    document.querySelector('.js-search-project-options').setAttribute('data-issues-disabled', true);
  };

  // Mock `gl` object in window for dashboard specific page. App code will need it.
  mockDashboardOptions = function() {
    window.gl || (window.gl = {});
    return (window.gl.dashboardOptions = {
      issuesPath: dashboardIssuesPath,
      mrPath: dashboardMRsPath,
    });
  };

  // Mock `gl` object in window for project specific page. App code will need it.
  mockProjectOptions = function() {
    window.gl || (window.gl = {});
    return (window.gl.projectOptions = {
      'gitlab-ce': {
        issuesPath: projectIssuesPath,
        mrPath: projectMRsPath,
        projectName: projectName,
      },
    });
  };

  mockGroupOptions = function() {
    window.gl || (window.gl = {});
    return (window.gl.groupOptions = {
      'gitlab-org': {
        issuesPath: groupIssuesPath,
        mrPath: groupMRsPath,
        projectName: groupName,
      },
    });
  };

  assertLinks = function(list, issuesPath, mrsPath) {
    if (issuesPath) {
      const issuesAssignedToMeLink = `a[href="${issuesPath}/?assignee_id=${userId}"]`;
      const issuesIHaveCreatedLink = `a[href="${issuesPath}/?author_id=${userId}"]`;
      expect(list.find(issuesAssignedToMeLink).length).toBe(1);
      expect(list.find(issuesAssignedToMeLink).text()).toBe('Issues assigned to me');
      expect(list.find(issuesIHaveCreatedLink).length).toBe(1);
      expect(list.find(issuesIHaveCreatedLink).text()).toBe("Issues I've created");
    }
    const mrsAssignedToMeLink = `a[href="${mrsPath}/?assignee_id=${userId}"]`;
    const mrsIHaveCreatedLink = `a[href="${mrsPath}/?author_id=${userId}"]`;
    expect(list.find(mrsAssignedToMeLink).length).toBe(1);
    expect(list.find(mrsAssignedToMeLink).text()).toBe('Merge requests assigned to me');
    expect(list.find(mrsIHaveCreatedLink).length).toBe(1);
    expect(list.find(mrsIHaveCreatedLink).text()).toBe("Merge requests I've created");
  };

  preloadFixtures('static/search_autocomplete.html.raw');
  beforeEach(function() {
    loadFixtures('static/search_autocomplete.html.raw');

    window.gon = {};
    window.gon.current_user_id = userId;
    window.gon.current_username = userName;

    return (widget = new SearchAutocomplete());
  });

  afterEach(function() {
    // Undo what we did to the shared <body>
    removeBodyAttributes();
    window.gon = {};
  });
  it('should show Dashboard specific dropdown menu', function() {
    var list;
    addBodyAttributes();
    mockDashboardOptions();
    widget.searchInput.triggerHandler('focus');
    list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, dashboardIssuesPath, dashboardMRsPath);
  });
  it('should show Group specific dropdown menu', function() {
    var list;
    addBodyAttributes('group');
    mockGroupOptions();
    widget.searchInput.triggerHandler('focus');
    list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, groupIssuesPath, groupMRsPath);
  });
  it('should show Project specific dropdown menu', function() {
    var list;
    addBodyAttributes('project');
    mockProjectOptions();
    widget.searchInput.triggerHandler('focus');
    list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, projectIssuesPath, projectMRsPath);
  });
  it('should show only Project mergeRequest dropdown menu items when project issues are disabled', function() {
    addBodyAttributes('project');
    disableProjectIssues();
    mockProjectOptions();
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    assertLinks(list, null, projectMRsPath);
  });
  it('should not show category related menu if there is text in the input', function() {
    var link, list;
    addBodyAttributes('project');
    mockProjectOptions();
    widget.searchInput.val('help');
    widget.searchInput.triggerHandler('focus');
    list = widget.wrap.find('.dropdown-menu').find('ul');
    link = "a[href='" + projectIssuesPath + '/?assignee_id=' + userId + "']";
    return expect(list.find(link).length).toBe(0);
  });
  it('should not submit the search form when selecting an autocomplete row with the keyboard', function() {
    var ENTER = 13;
    var DOWN = 40;
    addBodyAttributes();
    mockDashboardOptions(true);
    var submitSpy = spyOnEvent('form', 'submit');
    widget.searchInput.triggerHandler('focus');
    widget.wrap.trigger($.Event('keydown', { which: DOWN }));
    var enterKeyEvent = $.Event('keydown', { which: ENTER });
    widget.searchInput.trigger(enterKeyEvent);
    // This does not currently catch failing behavior. For security reasons,
    // browsers will not trigger default behavior (form submit, in this
    // example) on JavaScript-created keypresses.
    expect(submitSpy).not.toHaveBeenTriggered();
  });
});
