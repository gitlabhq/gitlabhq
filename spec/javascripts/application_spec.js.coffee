#= require lib/utils/common_utils

describe 'Application', ->
  describe 'disable buttons', ->
    fixture.preload('application.html')

    beforeEach ->
      fixture.load('application.html')

    it 'should prevent default action for disabled buttons', ->

      gl.utils.preventDisabledButtons()

      isClicked = false
      $button   = $ '#test-button'

      $button.click -> isClicked = true
      $button.trigger 'click'

      expect(isClicked).toBe false


    it 'should be on the same page if a disabled link clicked', ->

      locationBeforeLinkClick = window.location.href
      gl.utils.preventDisabledButtons()

      $('#test-link').click()

      expect(window.location.href).toBe locationBeforeLinkClick
