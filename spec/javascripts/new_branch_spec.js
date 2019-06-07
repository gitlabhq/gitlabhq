import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';

describe('Branch', function() {
  describe('create a new branch', function() {
    preloadFixtures('branches/new_branch.html');

    function fillNameWith(value) {
      $('.js-branch-name')
        .val(value)
        .trigger('blur');
    }

    function expectToHaveError(error) {
      expect($('.js-branch-name-error span').text()).toEqual(error);
    }

    beforeEach(function() {
      loadFixtures('branches/new_branch.html');
      $('form').on('submit', function(e) {
        return e.preventDefault();
      });
      this.form = new NewBranchForm($('.js-create-branch-form'), []);
    });

    it("can't start with a dot", function() {
      fillNameWith('.foo');
      expectToHaveError("can't start with '.'");
    });

    it("can't start with a slash", function() {
      fillNameWith('/foo');
      expectToHaveError("can't start with '/'");
    });

    it("can't have two consecutive dots", function() {
      fillNameWith('foo..bar');
      expectToHaveError("can't contain '..'");
    });

    it("can't have spaces anywhere", function() {
      fillNameWith(' foo');
      expectToHaveError("can't contain spaces");
      fillNameWith('foo bar');
      expectToHaveError("can't contain spaces");
      fillNameWith('foo ');
      expectToHaveError("can't contain spaces");
    });

    it("can't have ~ anywhere", function() {
      fillNameWith('~foo');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~bar');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~');
      expectToHaveError("can't contain '~'");
    });

    it("can't have tilde anwhere", function() {
      fillNameWith('~foo');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~bar');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~');
      expectToHaveError("can't contain '~'");
    });

    it("can't have caret anywhere", function() {
      fillNameWith('^foo');
      expectToHaveError("can't contain '^'");
      fillNameWith('foo^bar');
      expectToHaveError("can't contain '^'");
      fillNameWith('foo^');
      expectToHaveError("can't contain '^'");
    });

    it("can't have : anywhere", function() {
      fillNameWith(':foo');
      expectToHaveError("can't contain ':'");
      fillNameWith('foo:bar');
      expectToHaveError("can't contain ':'");
      fillNameWith(':foo');
      expectToHaveError("can't contain ':'");
    });

    it("can't have question mark anywhere", function() {
      fillNameWith('?foo');
      expectToHaveError("can't contain '?'");
      fillNameWith('foo?bar');
      expectToHaveError("can't contain '?'");
      fillNameWith('foo?');
      expectToHaveError("can't contain '?'");
    });

    it("can't have asterisk anywhere", function() {
      fillNameWith('*foo');
      expectToHaveError("can't contain '*'");
      fillNameWith('foo*bar');
      expectToHaveError("can't contain '*'");
      fillNameWith('foo*');
      expectToHaveError("can't contain '*'");
    });

    it("can't have open bracket anywhere", function() {
      fillNameWith('[foo');
      expectToHaveError("can't contain '['");
      fillNameWith('foo[bar');
      expectToHaveError("can't contain '['");
      fillNameWith('foo[');
      expectToHaveError("can't contain '['");
    });

    it("can't have a backslash anywhere", function() {
      fillNameWith('\\foo');
      expectToHaveError("can't contain '\\'");
      fillNameWith('foo\\bar');
      expectToHaveError("can't contain '\\'");
      fillNameWith('foo\\');
      expectToHaveError("can't contain '\\'");
    });

    it("can't contain a sequence @{ anywhere", function() {
      fillNameWith('@{foo');
      expectToHaveError("can't contain '@{'");
      fillNameWith('foo@{bar');
      expectToHaveError("can't contain '@{'");
      fillNameWith('foo@{');
      expectToHaveError("can't contain '@{'");
    });

    it("can't have consecutive slashes", function() {
      fillNameWith('foo//bar');
      expectToHaveError("can't contain consecutive slashes");
    });

    it("can't end with a slash", function() {
      fillNameWith('foo/');
      expectToHaveError("can't end in '/'");
    });

    it("can't end with a dot", function() {
      fillNameWith('foo.');
      expectToHaveError("can't end in '.'");
    });

    it("can't end with .lock", function() {
      fillNameWith('foo.lock');
      expectToHaveError("can't end in '.lock'");
    });

    it("can't be the single character @", function() {
      fillNameWith('@');
      expectToHaveError("can't be '@'");
    });

    it('concatenates all error messages', function() {
      fillNameWith('/foo bar?~.');
      expectToHaveError("can't start with '/', can't contain spaces, '?', '~', can't end in '.'");
    });

    it("doesn't duplicate error messages", function() {
      fillNameWith('?foo?bar?zoo?');
      expectToHaveError("can't contain '?'");
    });

    it('removes the error message when is a valid name', function() {
      fillNameWith('foo?bar');

      expect($('.js-branch-name-error span').length).toEqual(1);
      fillNameWith('foobar');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have dashes anywhere', function() {
      fillNameWith('-foo-bar-zoo-');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have underscores anywhere', function() {
      fillNameWith('_foo_bar_zoo_');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have numbers anywhere', function() {
      fillNameWith('1foo2bar3zoo4');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can be only letters', function() {
      fillNameWith('foo');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });
  });
});
