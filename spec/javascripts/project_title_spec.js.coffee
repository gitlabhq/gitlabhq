#= require select2
#= require api
#= require project_select
#= require project

window.gon = {}
window.gon.api_version = 'v3'

describe 'Project Title', ->
  fixture.preload('project_title.html')
  fixture.preload('projects.json')

  beforeEach ->
    fixture.load('project_title.html')
    @project = new Project()

    spyOn(@project, 'changeProject').and.callFake (url) ->
      window.current_project_url = url

  describe 'project list', ->
    beforeEach =>
      @projects_data = fixture.load('projects.json')[0]

      spyOn(jQuery, 'ajax').and.callFake (req) =>
        expect(req.url).toBe('/api/v3/projects.json')
        d = $.Deferred()
        d.resolve @projects_data
        d.promise()

    it 'to show on toggle click', =>
      $('.js-projects-dropdown-toggle').click()

      expect($('.title .select2-container').hasClass('select2-dropdown-open')).toBe(true)
      expect($('.ajax-project-dropdown li').length).toBe(@projects_data.length)

    it 'hide dropdown', ->
      $("#select2-drop-mask").click()

      expect($('.title .select2-container').hasClass('select2-dropdown-open')).toBe(false)

    it 'change project when clicking item', ->
      $('.js-projects-dropdown-toggle').click()
      $('.ajax-project-dropdown li:nth-child(2)').trigger('mouseup')

      expect($('.title .select2-container').hasClass('select2-dropdown-open')).toBe(false)
      expect(window.current_project_url).toBe('http://localhost:3000/h5bp/html5-boilerplate')
