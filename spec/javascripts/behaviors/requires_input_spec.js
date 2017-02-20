/* eslint-disable space-before-function-paren, no-var */

require('~/behaviors/requires_input');

(function() {
  describe('requiresInput', function() {
    preloadFixtures('branches/new_branch.html.raw');
    beforeEach(function() {
      loadFixtures('branches/new_branch.html.raw');
      this.submitButton = $('button[type="submit"]');
    });
    it('disables submit when any field is required', function() {
      $('.js-requires-input').requiresInput();
      return expect(this.submitButton).toBeDisabled();
    });
    it('enables submit when no field is required', function() {
      $('*[required=required]').removeAttr('required');
      $('.js-requires-input').requiresInput();
      return expect(this.submitButton).not.toBeDisabled();
    });
    it('enables submit when all required fields are pre-filled', function() {
      $('*[required=required]').remove();
      $('.js-requires-input').requiresInput();
      return expect($('.submit')).not.toBeDisabled();
    });
    it('enables submit when all required fields receive input', function() {
      $('.js-requires-input').requiresInput();
      $('#required1').val('input1').change();
      expect(this.submitButton).toBeDisabled();
      $('#optional1').val('input1').change();
      expect(this.submitButton).toBeDisabled();
      $('#required2').val('input2').change();
      $('#required3').val('input3').change();
      $('#required4').val('input4').change();
      $('#required5').val('1').change();
      return expect($('.submit')).not.toBeDisabled();
    });
  });
}).call(window);
