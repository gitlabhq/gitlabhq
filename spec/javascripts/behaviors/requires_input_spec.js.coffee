#= require behaviors/requires_input

describe 'requiresInput', ->
  fixture.preload('behaviors/requires_input.html')

  beforeEach ->
    fixture.load('behaviors/requires_input.html')

  it 'disables submit when any field is required', ->
    $('.js-requires-input').requiresInput()

    expect($('.submit')).toBeDisabled()

  it 'enables submit when no field is required', ->
    $('*[required=required]').removeAttr('required')

    $('.js-requires-input').requiresInput()

    expect($('.submit')).not.toBeDisabled()

  it 'enables submit when all required fields are pre-filled', ->
    $('*[required=required]').remove()

    $('.js-requires-input').requiresInput()

    expect($('.submit')).not.toBeDisabled()

  it 'enables submit when all required fields receive input', ->
    $('.js-requires-input').requiresInput()

    $('#required1').val('input1').change()
    expect($('.submit')).toBeDisabled()

    $('#optional1').val('input1').change()
    expect($('.submit')).toBeDisabled()

    $('#required2').val('input2').change()
    $('#required3').val('input3').change()
    $('#required4').val('input4').change()
    $('#required5').val('1').change()

    expect($('.submit')).not.toBeDisabled()

  it 'is called on page:load event', ->
    spy = spyOn($.fn, 'requiresInput')

    $(document).trigger('page:load')

    expect(spy).toHaveBeenCalled()
