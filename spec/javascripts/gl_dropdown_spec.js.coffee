#= require jquery
#= require gl_dropdown
#= require turbolinks
#= require lib/utils/common_utils
#= require lib/utils/type_utility

NON_SELECTABLE_CLASSES = '.divider, .separator, .dropdown-header, .dropdown-menu-empty-link'
ITEM_SELECTOR = ".dropdown-content li:not(#{NON_SELECTABLE_CLASSES})"
FOCUSED_ITEM_SELECTOR = ITEM_SELECTOR + ' a.is-focused'

ARROW_KEYS =
  DOWN: 40
  UP: 38
  ENTER: 13
  ESC: 27

navigateWithKeys = (direction, steps, cb, i) ->
  i = i || 0
  $('body').trigger
    type: 'keydown'
    which: ARROW_KEYS[direction.toUpperCase()]
    keyCode: ARROW_KEYS[direction.toUpperCase()]
  i++
  if i <= steps
    navigateWithKeys direction, steps, cb, i
  else
    cb()

initDropdown = ->
  @dropdownContainerElement = $('.dropdown.inline')
  @dropdownMenuElement = $('.dropdown-menu', @dropdownContainerElement)
  @projectsData = fixture.load('projects.json')[0]
  @dropdownButtonElement = $('#js-project-dropdown', @dropdownContainerElement).glDropdown
    selectable: true
    data: @projectsData
    text: (project) ->
      (project.name_with_namespace or project.name)
    id: (project) ->
      project.id

describe 'Dropdown', ->
  fixture.preload 'gl_dropdown.html'
  fixture.preload 'projects.json'

  beforeEach ->
    fixture.load 'gl_dropdown.html'
    initDropdown.call this

  afterEach ->
    $('body').unbind 'keydown'
    @dropdownContainerElement.unbind 'keyup'

  it 'should open on click', ->
    expect(@dropdownContainerElement).not.toHaveClass 'open'
    @dropdownButtonElement.click()
    expect(@dropdownContainerElement).toHaveClass 'open'

  describe 'that is open', ->
    beforeEach ->
      @dropdownButtonElement.click()

    it 'should select a following item on DOWN keypress', ->
      expect($(FOCUSED_ITEM_SELECTOR, @dropdownMenuElement).length).toBe 0
      randomIndex = Math.floor(Math.random() * (@projectsData.length - 1)) + 0
      navigateWithKeys 'down', randomIndex, =>
        expect($(FOCUSED_ITEM_SELECTOR, @dropdownMenuElement).length).toBe 1
        expect($("#{ITEM_SELECTOR}:eq(#{randomIndex}) a", @dropdownMenuElement)).toHaveClass 'is-focused'

    it 'should select a previous item on UP keypress', ->
      expect($(FOCUSED_ITEM_SELECTOR, @dropdownMenuElement).length).toBe 0
      navigateWithKeys 'down', (@projectsData.length - 1), =>
        expect($(FOCUSED_ITEM_SELECTOR, @dropdownMenuElement).length).toBe 1
        randomIndex = Math.floor(Math.random() * (@projectsData.length - 2)) + 0
        navigateWithKeys 'up', randomIndex, =>
          expect($(FOCUSED_ITEM_SELECTOR, @dropdownMenuElement).length).toBe 1
          expect($("#{ITEM_SELECTOR}:eq(#{((@projectsData.length - 2) - randomIndex)}) a", @dropdownMenuElement)).toHaveClass 'is-focused'

    it 'should click the selected item on ENTER keypress', ->
      expect(@dropdownContainerElement).toHaveClass 'open'
      randomIndex = Math.floor(Math.random() * (@projectsData.length - 1)) + 0
      navigateWithKeys 'down', randomIndex, =>
        spyOn(Turbolinks, 'visit').and.stub()
        navigateWithKeys 'enter', null, =>
          expect(@dropdownContainerElement).not.toHaveClass 'open'
          link = $("#{ITEM_SELECTOR}:eq(#{randomIndex}) a", @dropdownMenuElement)
          expect(link).toHaveClass 'is-active'
          linkedLocation = link.attr 'href'
          if linkedLocation and linkedLocation isnt '#'
            expect(Turbolinks.visit).toHaveBeenCalledWith linkedLocation

    it 'should close on ESC keypress', ->
      expect(@dropdownContainerElement).toHaveClass 'open'
      @dropdownContainerElement.trigger
        type: 'keyup'
        which: ARROW_KEYS.ESC
        keyCode: ARROW_KEYS.ESC
      expect(@dropdownContainerElement).not.toHaveClass 'open'
