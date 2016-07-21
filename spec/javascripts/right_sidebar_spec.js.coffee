###
//= require right_sidebar
###
###
//= require jquery
###
###
//= require jquery.cookie
###

@sidebar    = null
$aside      = null
$toggle     = null
$icon       = null
$page       = null
$labelsIcon = null


assertSidebarState = (state) ->

  shouldBeExpanded  = state is 'expanded'
  shouldBeCollapsed = state is 'collapsed'

  expect($aside.hasClass('right-sidebar-expanded')).toBe shouldBeExpanded
  expect($page.hasClass('right-sidebar-expanded')).toBe shouldBeExpanded
  expect($icon.hasClass('fa-angle-double-right')).toBe shouldBeExpanded

  expect($aside.hasClass('right-sidebar-collapsed')).toBe shouldBeCollapsed
  expect($page.hasClass('right-sidebar-collapsed')).toBe shouldBeCollapsed
  expect($icon.hasClass('fa-angle-double-left')).toBe shouldBeCollapsed


describe 'RightSidebar', ->

  fixture.preload 'right_sidebar.html'

  beforeEach ->
    fixture.load 'right_sidebar.html'

    @sidebar    = new Sidebar
    $aside      = $ '.right-sidebar'
    $page       = $ '.page-with-sidebar'
    $icon       = $aside.find 'i'
    $toggle     = $aside.find '.js-sidebar-toggle'
    $labelsIcon = $aside.find '.sidebar-collapsed-icon'


  it 'should expand the sidebar when arrow is clicked', ->

    $toggle.click()
    assertSidebarState 'expanded'


  it 'should collapse the sidebar when arrow is clicked', ->

    $toggle.click()
    assertSidebarState 'expanded'

    $toggle.click()
    assertSidebarState 'collapsed'


  it 'should float over the page and when sidebar icons clicked', ->

    $labelsIcon.click()
    assertSidebarState 'expanded'


  it 'should collapse when the icon arrow clicked while it is floating on page', ->

    $labelsIcon.click()
    assertSidebarState 'expanded'

    $toggle.click()
    assertSidebarState 'collapsed'
