
/*= require syntax_highlight */

(function() {
  describe('Syntax Highlighter', function() {
    var stubUserColorScheme;
    stubUserColorScheme = function(value) {
      if (window.gon == null) {
        window.gon = {};
      }
      return window.gon.user_color_scheme = value;
    };
    describe('on a js-syntax-highlight element', function() {
      beforeEach(function() {
        return fixture.set('<div class="js-syntax-highlight"></div>');
      });
      return it('applies syntax highlighting', function() {
        stubUserColorScheme('monokai');
        $('.js-syntax-highlight').syntaxHighlight();
        return expect($('.js-syntax-highlight')).toHaveClass('monokai');
      });
    });
    return describe('on a parent element', function() {
      beforeEach(function() {
        return fixture.set("<div class=\"parent\">\n  <div class=\"js-syntax-highlight\"></div>\n  <div class=\"foo\"></div>\n  <div class=\"js-syntax-highlight\"></div>\n</div>");
      });
      it('applies highlighting to all applicable children', function() {
        stubUserColorScheme('monokai');
        $('.parent').syntaxHighlight();
        expect($('.parent, .foo')).not.toHaveClass('monokai');
        return expect($('.monokai').length).toBe(2);
      });
      return it('prevents an infinite loop when no matches exist', function() {
        var highlight;
        fixture.set('<div></div>');
        highlight = function() {
          return $('div').syntaxHighlight();
        };
        return expect(highlight).not.toThrow();
      });
    });
  });

}).call(this);
