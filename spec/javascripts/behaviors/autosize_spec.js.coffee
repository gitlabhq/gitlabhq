#= require behaviors/autosize

describe 'Autosize behavior', ->
  beforeEach ->
    fixture.set('<textarea class="js-autosize" style="resize: vertical"></textarea>')

  it 'does not overwrite the resize property', ->
    load()
    expect($('textarea')).toHaveCss(resize: 'vertical')

  load = -> $(document).trigger('page:load')
