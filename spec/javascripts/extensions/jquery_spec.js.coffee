#= require extensions/jquery

describe 'jQuery extensions', ->
  describe 'disable', ->
    beforeEach ->
      fixture.set '<input type="text" />'

    it 'adds the disabled attribute', ->
      $input = $('input').first()

      $input.disable()
      expect($input).toHaveAttr('disabled', 'disabled')

    it 'adds the disabled class', ->
      $input = $('input').first()

      $input.disable()
      expect($input).toHaveClass('disabled')

  describe 'enable', ->
    beforeEach ->
      fixture.set '<input type="text" disabled="disabled" class="disabled" />'

    it 'removes the disabled attribute', ->
      $input = $('input').first()

      $input.enable()
      expect($input).not.toHaveAttr('disabled')

    it 'removes the disabled class', ->
      $input = $('input').first()

      $input.enable()
      expect($input).not.toHaveClass('disabled')
