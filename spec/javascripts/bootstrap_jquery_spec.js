/* eslint-disable space-before-function-paren, no-var */

import $ from 'jquery';
import '~/commons/bootstrap';

(function() {
  describe('Bootstrap jQuery extensions', function() {
    describe('disable', function() {
      beforeEach(function() {
        return setFixtures('<input type="text" />');
      });
      it('adds the disabled attribute', function() {
        var $input;
        $input = $('input').first();
        $input.disable();
        return expect($input).toHaveAttr('disabled', 'disabled');
      });
      return it('adds the disabled class', function() {
        var $input;
        $input = $('input').first();
        $input.disable();
        return expect($input).toHaveClass('disabled');
      });
    });
    return describe('enable', function() {
      beforeEach(function() {
        return setFixtures('<input type="text" disabled="disabled" class="disabled" />');
      });
      it('removes the disabled attribute', function() {
        var $input;
        $input = $('input').first();
        $input.enable();
        return expect($input).not.toHaveAttr('disabled');
      });
      return it('removes the disabled class', function() {
        var $input;
        $input = $('input').first();
        $input.enable();
        return expect($input).not.toHaveClass('disabled');
      });
    });
  });
}).call(window);
