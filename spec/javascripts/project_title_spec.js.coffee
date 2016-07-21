###
//= require bootstrap
###
###
//= require select2
###
###
//= require lib/utils/type_utility
###
###
//= require gl_dropdown
###
###
//= require api
###
###
//= require project_select
###
###
//= require project
###

window.gon or= {}
window.gon.api_version = 'v3'

describe 'Project Title', ->
  fixture.preload('project_title.html')
  fixture.preload('projects.json')

  beforeEach ->
    fixture.load('project_title.html')
    @project = new Project()

  describe 'project list', ->
    beforeEach =>
      @projects_data = fixture.load('projects.json')[0]

      spyOn(jQuery, 'ajax').and.callFake (req) =>
        expect(req.url).toBe('/api/v3/projects.json?simple=true')
        d = $.Deferred()
        d.resolve @projects_data
        d.promise()

    it 'to show on toggle click', =>
      $('.js-projects-dropdown-toggle').click()
      expect($('.header-content').hasClass('open')).toBe(true)

    it 'hide dropdown', ->
      $(".dropdown-menu-close-icon").click()

      expect($('.header-content').hasClass('open')).toBe(false)
