#= require gl_dropdown
#= require search_autocomplete
#= require jquery
#= require lib/common_utils
#= require lib/type_utility
#= require fuzzaldrin-plus


widget       = null
userId       = 1
window.gon or= {}
window.gon.current_user_id = userId

dashboardIssuesPath = '/dashboard/issues'
dashboardMRsPath    = '/dashboard/merge_requests'
projectIssuesPath   = "/gitlab-org/gitlab-ce/issues"
projectMRsPath      = "/gitlab-org/gitlab-ce/merge_requests"
projectName         = 'GitLab Community Edition'

# Add required attributes to body before starting the test.
addBodyAttributes = (page = 'groups') ->

  $('body').removeAttr 'data-page'
  $('body').removeAttr 'data-project'

  $('body').data 'page', "#{page}:show"
  $('body').data 'project', 'gitlab-ce'


# Mock `gl` object in window for dashboard specific page. App code will need it.
mockDashboardOptions = ->

  window.gl or= {}
  window.gl.dashboardOptions =
    issuesPath: dashboardIssuesPath
    mrPath    : dashboardMRsPath


# Mock `gl` object in window for project specific page. App code will need it.
mockProjectOptions = ->

  window.gl or= {}
  window.gl.projectOptions =
    'gitlab-ce'   :
      issuesPath  : projectIssuesPath
      mrPath      : projectMRsPath
      projectName : projectName


assertLinks = (list, a1, a2, a3, a4) ->

  expect(list.find(a1).length).toBe 1
  expect(list.find(a1).text()).toBe ' Issues assigned to me '

  expect(list.find(a2).length).toBe 1
  expect(list.find(a2).text()).toBe " Issues I've created "

  expect(list.find(a3).length).toBe 1
  expect(list.find(a3).text()).toBe ' Merge requests assigned to me '

  expect(list.find(a4).length).toBe 1
  expect(list.find(a4).text()).toBe " Merge requests I've created "



describe 'Search autocomplete dropdown', ->

  fixture.preload 'search_autocomplete.html'

  beforeEach ->

    fixture.load 'search_autocomplete.html'
    widget = new SearchAutocomplete


  it 'should show Dashboard specific dropdown menu', ->

    addBodyAttributes()
    mockDashboardOptions()

    # Focus input to show dropdown list.
    widget.searchInput.focus()

    w = widget.wrap.find '.dropdown-menu'
    l = w.find 'ul'

    # # Expect dropdown and dropdown header
    expect(w.find('.dropdown-header').text()).toBe 'Go to in Dashboard'

    # Create links then assert link urls and inner texts
    issuesAssignedToMeLink = "#{dashboardIssuesPath}/?assignee_id=#{userId}"
    issuesIHaveCreatedLink = "#{dashboardIssuesPath}/?author_id=#{userId}"
    mrsAssignedToMeLink    = "#{dashboardMRsPath}/?assignee_id=#{userId}"
    mrsIHaveCreatedLink    = "#{dashboardMRsPath}/?author_id=#{userId}"

    a1 = "a[href='#{issuesAssignedToMeLink}']"
    a2 = "a[href='#{issuesIHaveCreatedLink}']"
    a3 = "a[href='#{mrsAssignedToMeLink}']"
    a4 = "a[href='#{mrsIHaveCreatedLink}']"

    assertLinks l, a1, a2, a3, a4


  it 'should show Project specific dropdown menu', ->

    addBodyAttributes 'projects'
    mockProjectOptions()

    # Focus input to show dropdown list.
    widget.searchInput.focus()

    w = widget.wrap.find '.dropdown-menu'
    l = w.find 'ul'

    # Expect dropdown and dropdown header
    expect(w.find('.dropdown-header').text()).toBe "Go to in #{projectName}"

    # Create links then verify link urls and inner texts
    issuesAssignedToMeLink = "#{projectIssuesPath}/?assignee_id=#{userId}"
    issuesIHaveCreatedLink = "#{projectIssuesPath}/?author_id=#{userId}"
    mrsAssignedToMeLink    = "#{projectMRsPath}/?assignee_id=#{userId}"
    mrsIHaveCreatedLink    = "#{projectMRsPath}/?author_id=#{userId}"

    a1 = "a[href='#{issuesAssignedToMeLink}']"
    a2 = "a[href='#{issuesIHaveCreatedLink}']"
    a3 = "a[href='#{mrsAssignedToMeLink}']"
    a4 = "a[href='#{mrsIHaveCreatedLink}']"

    assertLinks l, a1, a2, a3, a4
