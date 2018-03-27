/* eslint-disable space-before-function-paren, one-var, no-var, one-var-declaration-per-line, no-return-assign, quotes, max-len */

import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';

(function() {
  describe('Branch', function() {
    return describe('create a new branch', function() {
      var expectToHaveError, fillNameWith;
      preloadFixtures('branches/new_branch.html.raw');
      fillNameWith = function(value) {
        return $('.js-branch-name').val(value).trigger('blur');
      };
      expectToHaveError = function(error) {
        return expect($('.js-branch-name-error span').text()).toEqual(error);
      };
      beforeEach(function() {
        loadFixtures('branches/new_branch.html.raw');
        $('form').on('submit', function(e) {
          return e.preventDefault();
        });
        return this.form = new NewBranchForm($('.js-create-branch-form'), []);
      });
      it("can't start with a dot", function() {
        fillNameWith('.foo');
        return expectToHaveError("can't start with '.'");
      });
      it("can't start with a slash", function() {
        fillNameWith('/foo');
        return expectToHaveError("can't start with '/'");
      });
      it("can't have two consecutive dots", function() {
        fillNameWith('foo..bar');
        return expectToHaveError("can't contain '..'");
      });
      it("can't have spaces anywhere", function() {
        fillNameWith(' foo');
        expectToHaveError("can't contain spaces");
        fillNameWith('foo bar');
        expectToHaveError("can't contain spaces");
        fillNameWith('foo ');
        return expectToHaveError("can't contain spaces");
      });
      it("can't have ~ anywhere", function() {
        fillNameWith('~foo');
        expectToHaveError("can't contain '~'");
        fillNameWith('foo~bar');
        expectToHaveError("can't contain '~'");
        fillNameWith('foo~');
        return expectToHaveError("can't contain '~'");
      });
      it("can't have tilde anwhere", function() {
        fillNameWith('~foo');
        expectToHaveError("can't contain '~'");
        fillNameWith('foo~bar');
        expectToHaveError("can't contain '~'");
        fillNameWith('foo~');
        return expectToHaveError("can't contain '~'");
      });
      it("can't have caret anywhere", function() {
        fillNameWith('^foo');
        expectToHaveError("can't contain '^'");
        fillNameWith('foo^bar');
        expectToHaveError("can't contain '^'");
        fillNameWith('foo^');
        return expectToHaveError("can't contain '^'");
      });
      it("can't have : anywhere", function() {
        fillNameWith(':foo');
        expectToHaveError("can't contain ':'");
        fillNameWith('foo:bar');
        expectToHaveError("can't contain ':'");
        fillNameWith(':foo');
        return expectToHaveError("can't contain ':'");
      });
      it("can't have question mark anywhere", function() {
        fillNameWith('?foo');
        expectToHaveError("can't contain '?'");
        fillNameWith('foo?bar');
        expectToHaveError("can't contain '?'");
        fillNameWith('foo?');
        return expectToHaveError("can't contain '?'");
      });
      it("can't have asterisk anywhere", function() {
        fillNameWith('*foo');
        expectToHaveError("can't contain '*'");
        fillNameWith('foo*bar');
        expectToHaveError("can't contain '*'");
        fillNameWith('foo*');
        return expectToHaveError("can't contain '*'");
      });
      it("can't have open bracket anywhere", function() {
        fillNameWith('[foo');
        expectToHaveError("can't contain '['");
        fillNameWith('foo[bar');
        expectToHaveError("can't contain '['");
        fillNameWith('foo[');
        return expectToHaveError("can't contain '['");
      });
      it("can't have a backslash anywhere", function() {
        fillNameWith('\\foo');
        expectToHaveError("can't contain '\\'");
        fillNameWith('foo\\bar');
        expectToHaveError("can't contain '\\'");
        fillNameWith('foo\\');
        return expectToHaveError("can't contain '\\'");
      });
      it("can't contain a sequence @{ anywhere", function() {
        fillNameWith('@{foo');
        expectToHaveError("can't contain '@{'");
        fillNameWith('foo@{bar');
        expectToHaveError("can't contain '@{'");
        fillNameWith('foo@{');
        return expectToHaveError("can't contain '@{'");
      });
      it("can't have consecutive slashes", function() {
        fillNameWith('foo//bar');
        return expectToHaveError("can't contain consecutive slashes");
      });
      it("can't end with a slash", function() {
        fillNameWith('foo/');
        return expectToHaveError("can't end in '/'");
      });
      it("can't end with a dot", function() {
        fillNameWith('foo.');
        return expectToHaveError("can't end in '.'");
      });
      it("can't end with .lock", function() {
        fillNameWith('foo.lock');
        return expectToHaveError("can't end in '.lock'");
      });
      it("can't be the single character @", function() {
        fillNameWith('@');
        return expectToHaveError("can't be '@'");
      });
      it("concatenates all error messages", function() {
        fillNameWith('/foo bar?~.');
        return expectToHaveError("can't start with '/', can't contain spaces, '?', '~', can't end in '.'");
      });
      it("doesn't duplicate error messages", function() {
        fillNameWith('?foo?bar?zoo?');
        return expectToHaveError("can't contain '?'");
      });
      it("removes the error message when is a valid name", function() {
        fillNameWith('foo?bar');
        expect($('.js-branch-name-error span').length).toEqual(1);
        fillNameWith('foobar');
        return expect($('.js-branch-name-error span').length).toEqual(0);
      });
      it("can have dashes anywhere", function() {
        fillNameWith('-foo-bar-zoo-');
        return expect($('.js-branch-name-error span').length).toEqual(0);
      });
      it("can have underscores anywhere", function() {
        fillNameWith('_foo_bar_zoo_');
        return expect($('.js-branch-name-error span').length).toEqual(0);
      });
      it("can have numbers anywhere", function() {
        fillNameWith('1foo2bar3zoo4');
        return expect($('.js-branch-name-error span').length).toEqual(0);
      });
      return it("can be only letters", function() {
        fillNameWith('foo');
        return expect($('.js-branch-name-error span').length).toEqual(0);
      });
    });
  });
}).call(window);
