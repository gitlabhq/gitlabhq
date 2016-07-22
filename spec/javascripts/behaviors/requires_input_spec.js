
/*= require behaviors/requires_input */
describe('requiresInput', function() {
  fixture.preload('behaviors/requires_input.html');
  beforeEach(function() {
    return fixture.load('behaviors/requires_input.html');
  });
  it('disables submit when any field is required', function() {
    $('.js-requires-input').requiresInput();
    return expect($('.submit')).toBeDisabled();
  });
  it('enables submit when no field is required', function() {
    $('*[required=required]').removeAttr('required');
    $('.js-requires-input').requiresInput();
    return expect($('.submit')).not.toBeDisabled();
  });
  it('enables submit when all required fields are pre-filled', function() {
    $('*[required=required]').remove();
    $('.js-requires-input').requiresInput();
    return expect($('.submit')).not.toBeDisabled();
  });
  it('enables submit when all required fields receive input', function() {
    $('.js-requires-input').requiresInput();
    $('#required1').val('input1').change();
    expect($('.submit')).toBeDisabled();
    $('#optional1').val('input1').change();
    expect($('.submit')).toBeDisabled();
    $('#required2').val('input2').change();
    $('#required3').val('input3').change();
    $('#required4').val('input4').change();
    $('#required5').val('1').change();
    return expect($('.submit')).not.toBeDisabled();
  });
  return it('is called on page:load event', function() {
    var spy;
    spy = spyOn($.fn, 'requiresInput');
    $(document).trigger('page:load');
    return expect(spy).toHaveBeenCalled();
  });
});
