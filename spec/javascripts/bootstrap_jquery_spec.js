import $ from 'jquery';
import '~/commons/bootstrap';

describe('Bootstrap jQuery extensions', function() {
  describe('disable', function() {
    beforeEach(function() {
      return setFixtures('<input type="text" />');
    });

    it('adds the disabled attribute', function() {
      const $input = $('input').first();
      $input.disable();

      expect($input).toHaveAttr('disabled', 'disabled');
    });
    return it('adds the disabled class', function() {
      const $input = $('input').first();
      $input.disable();

      expect($input).toHaveClass('disabled');
    });
  });
  return describe('enable', function() {
    beforeEach(function() {
      return setFixtures('<input type="text" disabled="disabled" class="disabled" />');
    });

    it('removes the disabled attribute', function() {
      const $input = $('input').first();
      $input.enable();

      expect($input).not.toHaveAttr('disabled');
    });
    return it('removes the disabled class', function() {
      const $input = $('input').first();
      $input.enable();

      expect($input).not.toHaveClass('disabled');
    });
  });
});
