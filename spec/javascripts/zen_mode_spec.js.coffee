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
    beforeEach -> enterZen()

    it 'exits on Escape', ->
      escapeKeydown()
      expect($('.zen-backdrop')).not.toHaveClass('fullscreen')

  describe 'on exit', ->
    beforeEach -> enterZen()

    it 'unpauses Mousetrap', ->
      spyOn(Mousetrap, 'unpause')
      exitZen()
      expect(Mousetrap.unpause).toHaveBeenCalled()

    it 'restores the scroll position', ->
      spyOn(@zen, 'scrollTo')
      exitZen()
      expect(@zen.scrollTo).toHaveBeenCalled()

enterZen      = -> $('a.js-zen-enter').click() # Ohmmmmmmm
exitZen       = -> $('a.js-zen-leave').click()
escapeKeydown = -> $('textarea').trigger($.Event('keydown', {keyCode: 27}))
