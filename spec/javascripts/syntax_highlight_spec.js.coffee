#= require syntax_highlight

describe 'Syntax Highlighter', ->
  stubUserColorScheme = (value) ->
    window.gon ?= {}
    window.gon.user_color_scheme = value

  describe 'on a js-syntax-highlight element', ->
    beforeEach ->
      fixture.set('<div class="js-syntax-highlight"></div>')

    it 'applies syntax highlighting', ->
      stubUserColorScheme('monokai')

      $('.js-syntax-highlight').syntaxHighlight()

      expect($('.js-syntax-highlight')).toHaveClass('monokai')

  describe 'on a parent element', ->
    beforeEach ->
      fixture.set """
        <div class="parent">
          <div class="js-syntax-highlight"></div>
          <div class="foo"></div>
          <div class="js-syntax-highlight"></div>
        </div>
      """

    it 'applies highlighting to all applicable children', ->
      stubUserColorScheme('monokai')

      $('.parent').syntaxHighlight()

      expect($('.parent, .foo')).not.toHaveClass('monokai')
      expect($('.monokai').length).toBe(2)

    it 'prevents an infinite loop when no matches exist', ->
      fixture.set('<div></div>')

      highlight = -> $('div').syntaxHighlight()

      expect(highlight).not.toThrow()
