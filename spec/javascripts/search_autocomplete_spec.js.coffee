###
//= require gl_dropdown
###
###
//= require search_autocomplete
###
###
//= require jquery
###
###
//= require lib/utils/common_utils
###
###
//= require lib/utils/type_utility
###
###
//= require fuzzaldrin-plus
###


widget       = null
userId       = 1
window.gon or= {}
window.gon.current_user_id = userId

dashboardIssuesPath = '/dashboard/issues'
dashboardMRsPath    = '/dashboard/merge_requests'
projectIssuesPath   = '/gitlab-org/gitlab-ce/issues'
projectMRsPath      = '/gitlab-org/gitlab-ce/merge_requests'
groupIssuesPath     = '/groups/gitlab-org/issues'
groupMRsPath        = '/groups/gitlab-org/merge_requests'
projectName         = 'GitLab Community Edition'
groupName           = 'Gitlab Org'


# Add required attributes to body before starting the test.
# section would be dashboard|group|project
addBodyAttributes = (section = 'dashboard') ->

  $body = $ 'body'

  $body.removeAttr 'data-page'
  $body.removeAttr 'data-project'
  $body.removeAttr 'data-group'

  switch section
    when 'dashboard'
      $body.data 'page', 'root:index'
    when 'group'
      $body.data 'page', 'groups:show'
      $body.data 'group', 'gitlab-org'
    when 'project'
      $body.data 'page', 'projects:show'
      $body.data 'project', 'gitlab-ce'


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


mockGroupOptions = ->

  window.gl or= {}
  window.gl.groupOptions =
    'gitlab-org'  :
      issuesPath  : groupIssuesPath
      mrPath      : groupMRsPath
      projectName : groupName


assertLinks = (list, issuesPath, mrsPath) ->

  issuesAssignedToMeLink = "#{issuesPath}/?assignee_id=#{userId}"
  issuesIHaveCreatedLink = "#{issuesPath}/?author_id=#{userId}"
  mrsAssignedToMeLink    = "#{mrsPath}/?assignee_id=#{userId}"
  mrsIHaveCreatedLink    = "#{mrsPath}/?author_id=#{userId}"

  a1 = "a[href='#{issuesAssignedToMeLink}']"
  a2 = "a[href='#{issuesIHaveCreatedLink}']"
  a3 = "a[href='#{mrsAssignedToMeLink}']"
  a4 = "a[href='#{mrsIHaveCreatedLink}']"

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
    widget.searchInput.focus()

    list = widget.wrap.find('.dropdown-menu').find 'ul'
    assertLinks list, dashboardIssuesPath, dashboardMRsPath


  it 'should show Group specific dropdown menu', ->

    addBodyAttributes 'group'
    mockGroupOptions()
    widget.searchInput.focus()

    list = widget.wrap.find('.dropdown-menu').find 'ul'
    assertLinks list, groupIssuesPath, groupMRsPath


  it 'should show Project specific dropdown menu', ->

    addBodyAttributes 'project'
    mockProjectOptions()
    widget.searchInput.focus()

    list = widget.wrap.find('.dropdown-menu').find 'ul'
    assertLinks list, projectIssuesPath, projectMRsPath


  it 'should not show category related menu if there is text in the input', ->

    addBodyAttributes 'project'
    mockProjectOptions()
    widget.searchInput.val 'help'
    widget.searchInput.focus()

    list = widget.wrap.find('.dropdown-menu').find 'ul'
    link = "a[href='#{projectIssuesPath}/?assignee_id=#{userId}']"
    expect(list.find(link).length).toBe 0
