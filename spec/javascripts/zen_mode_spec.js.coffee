#= require zen_mode

describe 'ZenMode', ->
  fixture.preload('zen_mode.html')

  beforeEach ->
    fixture.load('zen_mode.html')

    # Stub Dropzone.forElement(...).enable()
    spyOn(Dropzone, 'forElement').and.callFake ->
      enable: -> true

    @zen = new ZenMode()

    # Set this manually because we can't actually scroll the window
    @zen.scroll_position = 456

  # Ohmmmmmmm
  enterZen = ->
    $('.zen-toggle-comment').prop('checked', true).trigger('change')

  # Wh- what was that?!
  exitZen = ->
    $('.zen-toggle-comment').prop('checked', false).trigger('change')

  describe 'on enter', ->
    it 'pauses Mousetrap', ->
      spyOn(Mousetrap, 'pause')
      enterZen()
      expect(Mousetrap.pause).toHaveBeenCalled()

    it 'removes textarea styling', ->
      $('textarea').attr('style', 'height: 400px')
      enterZen()
      expect('textarea').not.toHaveAttr('style')

  describe 'in use', ->
    beforeEach ->
      enterZen()

    it 'exits on Escape', ->
      $(document).trigger(jQuery.Event('keydown', {keyCode: 27}))
      expect($('.zen-toggle-comment').prop('checked')).toBe(false)

  describe 'on exit', ->
    beforeEach ->
      enterZen()

    it 'unpauses Mousetrap', ->
      spyOn(Mousetrap, 'unpause')
      exitZen()
      expect(Mousetrap.unpause).toHaveBeenCalled()

    it 'restores the scroll position', ->
      spyOn(@zen, 'restoreScroll')
      exitZen()
      expect(@zen.restoreScroll).toHaveBeenCalledWith(456)
